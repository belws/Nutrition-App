import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nutrition_app/models/user_profile.dart';
import 'package:nutrition_app/repositories/user_profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const userId = '11111111-1111-4111-8111-111111111111';
  late HttpServer server;
  late UserProfileRepository repository;
  late Map<String, dynamic> storedRow;

  // A loopback-only PostgREST stub; no Supabase initialization or credentials.
  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    repository = UserProfileRepository(
      client: PostgrestClient('http://127.0.0.1:${server.port}'),
    );
    storedRow = {
      'user_id': userId,
      'sex': 'male',
      'date_of_birth': '1990-01-02',
      'height_cm': 180,
      'weight_kg': 80.5,
      'activity_level': 'lightly_active',
      'goal': 'maintain',
      'created_at': '2026-10-07T09:00:00Z',
      'updated_at': '2026-10-07T10:00:00Z',
    };
  });

  tearDown(() async {
    await server.close(force: true);
  });

  test('getProfile filters by user ID and returns null for no row', () async {
    server.listen((request) async {
      expect(request.method, 'GET');
      expect(request.uri.path, '/user_profiles');
      expect(request.uri.queryParameters['user_id'], 'eq.$userId');
      expect(request.headers.value('accept-profile'), 'public');
      request.response.headers.contentType = ContentType.json;
      request.response.write('[]');
      await request.response.close();
    });

    expect(await repository.getProfile(userId), isNull);
  });

  test('getProfile maps the returned row', () async {
    server.listen((request) async {
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode([storedRow]));
      await request.response.close();
    });

    final profile = await repository.getProfile(userId);
    expect(profile, isNotNull);
    expect(profile!.toJson(), UserProfile.fromJson(storedRow).toJson());
    expect(profile.createdAt, DateTime.utc(2026, 10, 7, 9));
    expect(profile.updatedAt, DateTime.utc(2026, 10, 7, 10));
  });

  test(
    'getProfile propagates PostgREST errors instead of returning null',
    () async {
      server.listen((request) async {
        request.response.statusCode = HttpStatus.forbidden;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'code': '42501',
            'message': 'permission denied for table user_profiles',
            'details': null,
            'hint': null,
          }),
        );
        await request.response.close();
      });

      await expectLater(
        repository.getProfile(userId),
        throwsA(isA<PostgrestException>()),
      );
    },
  );

  test('saveProfile upserts on user_id and returns stored values', () async {
    var writes = 0;
    server.listen((request) async {
      writes++;
      expect(request.method, 'POST');
      expect(request.uri.path, '/user_profiles');
      expect(request.uri.queryParameters['on_conflict'], 'user_id');
      expect(request.uri.queryParameters['select'], '*');
      expect(request.headers.value('content-profile'), 'public');
      expect(
        request.headers.value('prefer'),
        contains('resolution=merge-duplicates'),
      );
      expect(
        request.headers.value('prefer'),
        contains('return=representation'),
      );
      final payload = jsonDecode(
        await utf8.decoder.bind(request).join(),
      ) as Map<String, dynamic>;
      expect(payload, {
        'user_id': userId,
        'sex': 'male',
        'date_of_birth': '1990-01-02',
        'height_cm': 180.0,
        'weight_kg': writes == 1 ? 80.5 : 79.0,
        'activity_level': 'lightly_active',
        'goal': 'maintain',
      });
      expect(payload.containsKey('created_at'), isFalse);
      expect(payload.containsKey('updated_at'), isFalse);
      storedRow = {
        ...storedRow,
        ...payload,
        'updated_at': '2026-10-07T11:00:00Z',
      };
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode(storedRow));
      await request.response.close();
    });

    final initial = UserProfile(
      userId: userId,
      sex: 'male',
      dateOfBirth: DateTime(1990, 1, 2),
      heightCm: 180,
      weightKg: 80.5,
      activityLevel: 'lightly_active',
      goal: 'maintain',
    );
    final saved = await repository.saveProfile(initial);
    expect(saved.toJson(), initial.toJson());
    expect(saved.createdAt, DateTime.utc(2026, 10, 7, 9));
    expect(saved.updatedAt, DateTime.utc(2026, 10, 7, 11));

    final edited = UserProfile.fromJson({...storedRow, 'weight_kg': 79});
    final updated = await repository.saveProfile(edited);
    expect(updated.weightKg, 79.0);
    expect(updated.createdAt, saved.createdAt);
    expect(writes, 2);
  });
}
