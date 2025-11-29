import 'dart:convert';
import 'package:flutter/services.dart';

class AppConfig {
  static String? supabaseUrl;
  static String? supabaseAnonKey;
  static String? openAiApiKey;
  static String? geminiApiKey;
  static String? anthropicApiKey;
  static String? perplexityApiKey;
  static String? googleWebClientId;

  static Future<void> loadConfig() async {
    try {
      final String configString = await rootBundle.loadString('env.json');
      final Map<String, dynamic> config = json.decode(configString);

      supabaseUrl = config['SUPABASE_URL'] as String?;
      supabaseAnonKey = config['SUPABASE_ANON_KEY'] as String?;
      openAiApiKey = config['OPENAI_API_KEY'] as String?;
      geminiApiKey = config['GEMINI_API_KEY'] as String?;
      anthropicApiKey = config['ANTHROPIC_API_KEY'] as String?;
      perplexityApiKey = config['PERPLEXITY_API_KEY'] as String?;
      googleWebClientId = config['GOOGLE_WEB_CLIENT_ID'] as String?;

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception('Supabase URL and ANON KEY are required in env.json');
      }
    } catch (e) {
      throw Exception('Failed to load configuration: $e');
    }
  }
}

