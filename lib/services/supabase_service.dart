import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config.dart';

class SupabaseService {
  static SupabaseClient? _client;

  static Future<void> initialize() async {
    await AppConfig.loadConfig();

    if (AppConfig.supabaseUrl == null || AppConfig.supabaseAnonKey == null) {
      throw Exception('Supabase configuration is missing. Please check env.json');
    }

    await Supabase.initialize(
      url: AppConfig.supabaseUrl!,
      anonKey: AppConfig.supabaseAnonKey!,
    );

    _client = Supabase.instance.client;
  }

  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseService.initialize() first.');
    }
    return _client!;
  }

  static GoTrueClient get auth => client.auth;
}

