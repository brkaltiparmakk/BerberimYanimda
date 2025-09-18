import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    final url = const String.fromEnvironment('SUPABASE_URL');
    final anonKey = const String.fromEnvironment('SUPABASE_ANON_KEY');
    if (url.isEmpty || anonKey.isEmpty) {
      throw StateError('Supabase bağlantı bilgileri eksik. --dart-define ile SUPABASE_URL ve SUPABASE_ANON_KEY gönderin.');
    }

    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}
