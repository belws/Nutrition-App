import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';

class UserProfileRepository {
  UserProfileRepository({PostgrestClient? client})
    : _client = client ?? Supabase.instance.client.rest;

  final PostgrestClient _client;

  /// The caller supplies the user ID; RLS enforces ownership.
  /// Returns null when no profile row is visible to the current authenticated
  /// caller: either no row exists or RLS prevents visibility.
  Future<UserProfile?> getProfile(String userId) async {
    final row = await _client
        .schema('public')
        .from('user_profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    return row == null ? null : UserProfile.fromJson(row);
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    final row = await _client
        .schema('public')
        .from('user_profiles')
        .upsert(profile.toJson(), onConflict: 'user_id')
        .select()
        .single();

    return UserProfile.fromJson(row);
  }
}
