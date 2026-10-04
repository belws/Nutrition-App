import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repositories/food_repository.dart';
import 'screens/food_catalog_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (supabaseUrl.trim().isEmpty || supabaseAnonKey.trim().isEmpty) {
    throw StateError(
      'Missing Supabase configuration. Provide non-empty '
      '--dart-define=SUPABASE_URL and --dart-define=SUPABASE_ANON_KEY '
      'with the project URL and public client key.',
    );
  }

  await Supabase.initialize(url: supabaseUrl, publishableKey: supabaseAnonKey);

  runApp(MyApp(repository: FoodRepository()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.repository});

  final FoodRepository repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Catalog alimente',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: Colors.deepPurple)),
      home: FoodCatalogScreen(repository: repository),
    );
  }
}
