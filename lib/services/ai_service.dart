import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

/// Custom exception for AI service errors
class AIServiceException implements Exception {
  final String message;
  final AIServiceErrorType type;

  AIServiceException(this.message, {this.type = AIServiceErrorType.unknown});

  @override
  String toString() => message;
}

enum AIServiceErrorType {
  quotaExceeded,
  rateLimitExceeded,
  apiError,
  networkError,
  unknown,
}

class AIService {
  // Supported AI providers
  static String? get _openAiKey => AppConfig.openAiApiKey;
  static String? get _geminiKey => AppConfig.geminiApiKey;
  static String? get _anthropicKey => AppConfig.anthropicApiKey;

  /// Generate a task from a user prompt using available AI providers
  /// Tries providers in order: OpenAI -> Gemini -> Anthropic
  /// Returns a map with task details: title, description, difficulty, category, etc.
  Future<Map<String, dynamic>> generateTaskFromPrompt(String prompt) async {
    // Try OpenAI first
    if (_openAiKey != null && 
        _openAiKey!.isNotEmpty && 
        _openAiKey != 'your-openai-api-key-here') {
      try {
        return await _generateWithOpenAI(prompt);
      } catch (e) {
        if (e is AIServiceException && e.type == AIServiceErrorType.quotaExceeded) {
          // Quota exceeded, try next provider
        } else {
          rethrow;
        }
      }
    }

    // Try Gemini as fallback
    if (_geminiKey != null && 
        _geminiKey!.isNotEmpty && 
        _geminiKey != 'your-gemini-api-key-here') {
      try {
        return await _generateWithGemini(prompt);
      } catch (e) {
        // Try next provider
      }
    }

    // Try Anthropic as last resort
    if (_anthropicKey != null && 
        _anthropicKey!.isNotEmpty && 
        _anthropicKey != 'your-anthropic-api-key-here') {
      try {
        return await _generateWithAnthropic(prompt);
      } catch (e) {
        // All providers failed
      }
    }

    throw AIServiceException(
      'No AI API configured or all providers failed. Please add at least one API key (OPENAI_API_KEY, GEMINI_API_KEY, or ANTHROPIC_API_KEY) to env.json',
      type: AIServiceErrorType.apiError,
    );
  }

  /// Generate task using OpenAI
  Future<Map<String, dynamic>> _generateWithOpenAI(String prompt) async {
    final apiKey = _openAiKey!;

    try {
      // Use OpenAI Chat Completions API
      final response = await http.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini', // or 'gpt-3.5-turbo' for cheaper option
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful task management assistant. Generate task details from user prompts. Always respond with valid JSON only, no additional text.',
            },
            {
              'role': 'user',
              'content': 'Create a task from this prompt: "$prompt"\n\nRespond with JSON in this exact format:\n{\n  "title": "Task title",\n  "description": "Task description",\n  "difficulty": "Easy/Medium/Hard",\n  "category": "Work/Health/Learning/Personal/Social",\n  "estimated_duration": 30,\n  "suggested_due_date": "YYYY-MM-DD" or null\n}',
            },
          ],
          'temperature': 0.7,
          'max_tokens': 300,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final content = responseData['choices']?[0]?['message']?['content'] as String?;
        
        if (content == null) {
          throw Exception('No content in AI response');
        }

        // Parse JSON from response (remove markdown code blocks if present)
        String jsonContent = content.trim();
        if (jsonContent.startsWith('```json')) {
          jsonContent = jsonContent.substring(7);
        }
        if (jsonContent.startsWith('```')) {
          jsonContent = jsonContent.substring(3);
        }
        if (jsonContent.endsWith('```')) {
          jsonContent = jsonContent.substring(0, jsonContent.length - 3);
        }
        jsonContent = jsonContent.trim();

        final data = jsonDecode(jsonContent) as Map<String, dynamic>;
        
        return {
          'title': data['title'] ?? 'Generated Task',
          'description': data['description'] ?? '',
          'difficulty': _mapDifficulty(data['difficulty']?.toString().toLowerCase() ?? 'medium'),
          'category': data['category'] ?? 'Personal',
          'estimatedDuration': data['estimated_duration'],
          'suggestedDueDate': data['suggested_due_date'],
        };
      } else {
        // Parse error response
        try {
          final errorData = jsonDecode(response.body) as Map<String, dynamic>;
          final error = errorData['error'] as Map<String, dynamic>?;
          final errorType = error?['type'] as String?;
          final errorMessage = error?['message'] as String?;
          
          // Handle quota errors specifically
          if (response.statusCode == 429 || errorType == 'insufficient_quota') {
            throw AIServiceException(
              'OpenAI quota exceeded. Please check your billing or use manual task creation.',
              type: AIServiceErrorType.quotaExceeded,
            );
          }
          
          // Handle rate limit errors
          if (errorType == 'rate_limit_exceeded') {
            throw AIServiceException(
              'OpenAI rate limit exceeded. Please try again in a moment.',
              type: AIServiceErrorType.rateLimitExceeded,
            );
          }
          
          throw AIServiceException(
            errorMessage ?? 'OpenAI API error: ${response.statusCode}',
            type: AIServiceErrorType.apiError,
          );
        } catch (e) {
          if (e is AIServiceException) rethrow;
          throw AIServiceException(
            'OpenAI API error: ${response.statusCode} - ${response.body}',
            type: AIServiceErrorType.apiError,
          );
        }
      }
    } catch (e) {
      if (e is FormatException) {
        throw Exception('Failed to parse AI response. Please try again.');
      }
      rethrow;
    }
  }

  /// Generate task using Google Gemini
  Future<Map<String, dynamic>> _generateWithGemini(String prompt) async {
    final apiKey = _geminiKey!;

    try {
      final response = await http.post(
        Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent?key=$apiKey'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text': 'You are a helpful task management assistant. Generate task details from user prompts. Always respond with valid JSON only, no additional text.\n\nCreate a task from this prompt: "$prompt"\n\nRespond with JSON in this exact format:\n{\n  "title": "Task title",\n  "description": "Task description",\n  "difficulty": "Easy/Medium/Hard",\n  "category": "Work/Health/Learning/Personal/Social",\n  "estimated_duration": 30,\n  "suggested_due_date": "YYYY-MM-DD" or null\n}'
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 300,
          },
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final candidates = responseData['candidates'] as List?;
        if (candidates == null || candidates.isEmpty) {
          throw AIServiceException('No response from Gemini API', type: AIServiceErrorType.apiError);
        }

        final content = candidates[0]['content']?['parts']?[0]?['text'] as String?;
        if (content == null) {
          throw AIServiceException('No content in Gemini response', type: AIServiceErrorType.apiError);
        }

        // Parse JSON from response
        String jsonContent = content.trim();
        if (jsonContent.startsWith('```json')) {
          jsonContent = jsonContent.substring(7);
        }
        if (jsonContent.startsWith('```')) {
          jsonContent = jsonContent.substring(3);
        }
        if (jsonContent.endsWith('```')) {
          jsonContent = jsonContent.substring(0, jsonContent.length - 3);
        }
        jsonContent = jsonContent.trim();

        final data = jsonDecode(jsonContent) as Map<String, dynamic>;
        
        return {
          'title': data['title'] ?? 'Generated Task',
          'description': data['description'] ?? '',
          'difficulty': _mapDifficulty(data['difficulty']?.toString().toLowerCase() ?? 'medium'),
          'category': data['category'] ?? 'Personal',
          'estimatedDuration': data['estimated_duration'],
          'suggestedDueDate': data['suggested_due_date'],
        };
      } else {
        throw AIServiceException(
          'Gemini API error: ${response.statusCode} - ${response.body}',
          type: AIServiceErrorType.apiError,
        );
      }
    } catch (e) {
      if (e is AIServiceException) rethrow;
      if (e is FormatException) {
        throw AIServiceException('Failed to parse Gemini response. Please try again.', type: AIServiceErrorType.apiError);
      }
      throw AIServiceException('Gemini API error: ${e.toString()}', type: AIServiceErrorType.apiError);
    }
  }

  /// Generate task using Anthropic Claude
  Future<Map<String, dynamic>> _generateWithAnthropic(String prompt) async {
    final apiKey = _anthropicKey!;

    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-3-haiku-20240307', // Fast and affordable
          'max_tokens': 300,
          'messages': [
            {
              'role': 'user',
              'content': 'You are a helpful task management assistant. Generate task details from user prompts. Always respond with valid JSON only, no additional text.\n\nCreate a task from this prompt: "$prompt"\n\nRespond with JSON in this exact format:\n{\n  "title": "Task title",\n  "description": "Task description",\n  "difficulty": "Easy/Medium/Hard",\n  "category": "Work/Health/Learning/Personal/Social",\n  "estimated_duration": 30,\n  "suggested_due_date": "YYYY-MM-DD" or null\n}'
            }
          ],
          'temperature': 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final content = responseData['content'] as List?;
        if (content == null || content.isEmpty) {
          throw AIServiceException('No content in Anthropic response', type: AIServiceErrorType.apiError);
        }

        final text = content[0]['text'] as String?;
        if (text == null) {
          throw AIServiceException('No text in Anthropic response', type: AIServiceErrorType.apiError);
        }

        // Parse JSON from response
        String jsonContent = text.trim();
        if (jsonContent.startsWith('```json')) {
          jsonContent = jsonContent.substring(7);
        }
        if (jsonContent.startsWith('```')) {
          jsonContent = jsonContent.substring(3);
        }
        if (jsonContent.endsWith('```')) {
          jsonContent = jsonContent.substring(0, jsonContent.length - 3);
        }
        jsonContent = jsonContent.trim();

        final data = jsonDecode(jsonContent) as Map<String, dynamic>;
        
        return {
          'title': data['title'] ?? 'Generated Task',
          'description': data['description'] ?? '',
          'difficulty': _mapDifficulty(data['difficulty']?.toString().toLowerCase() ?? 'medium'),
          'category': data['category'] ?? 'Personal',
          'estimatedDuration': data['estimated_duration'],
          'suggestedDueDate': data['suggested_due_date'],
        };
      } else {
        throw AIServiceException(
          'Anthropic API error: ${response.statusCode} - ${response.body}',
          type: AIServiceErrorType.apiError,
        );
      }
    } catch (e) {
      if (e is AIServiceException) rethrow;
      if (e is FormatException) {
        throw AIServiceException('Failed to parse Anthropic response. Please try again.', type: AIServiceErrorType.apiError);
      }
      throw AIServiceException('Anthropic API error: ${e.toString()}', type: AIServiceErrorType.apiError);
    }
  }

  /// Get animation suggestion based on task title and description
  /// Returns animation type and mood for pixel art widget
  /// Uses keyword-based detection (fast and free) or OpenAI if needed
  Future<Map<String, dynamic>> getAnimationForTask({
    required String title,
    String? description,
  }) async {
    // For now, use keyword-based detection (fast and works offline)
    // You can enhance this to use OpenAI if you want more sophisticated detection
    return _getAnimationFromKeywords(title, description ?? '');
    
    // Optional: Use OpenAI for more sophisticated detection
    // Uncomment below if you want to use AI for animation detection
    /*
    final apiKey = _apiKey;
    if (apiKey == null || apiKey.isEmpty || apiKey == 'your-openai-api-key-here') {
      return _getAnimationFromKeywords(title, description ?? '');
    }

    try {
      final response = await http.post(
        Uri.parse('$_apiUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a task analyzer. Analyze tasks and suggest animation types. Respond with JSON only.',
            },
            {
              'role': 'user',
              'content': 'Task: "$title"\nDescription: "${description ?? ''}"\n\nRespond with JSON:\n{\n  "animation_type": "idle/working/running/reading/creating/cooking/walking",\n  "mood": "neutral/focused/energetic/curious/inspired/happy/casual",\n  "character": "default/worker/athlete/student/artist/chef/shopper"\n}',
            },
          ],
          'temperature': 0.3,
          'max_tokens': 100,
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body) as Map<String, dynamic>;
        final content = responseData['choices']?[0]?['message']?['content'] as String?;
        
        if (content != null) {
          String jsonContent = content.trim();
          if (jsonContent.startsWith('```json')) jsonContent = jsonContent.substring(7);
          if (jsonContent.startsWith('```')) jsonContent = jsonContent.substring(3);
          if (jsonContent.endsWith('```')) jsonContent = jsonContent.substring(0, jsonContent.length - 3);
          jsonContent = jsonContent.trim();
          
          final data = jsonDecode(jsonContent) as Map<String, dynamic>;
          return {
            'animationType': data['animation_type'] ?? 'idle',
            'mood': data['mood'] ?? 'neutral',
            'character': data['character'] ?? 'default',
          };
        }
      }
      // Fallback to keyword-based
      return _getAnimationFromKeywords(title, description ?? '');
    } catch (e) {
      // Fallback to keyword-based
      return _getAnimationFromKeywords(title, description ?? '');
    }
    */
  }

  /// Fallback: Simple keyword-based animation detection
  Map<String, dynamic> _getAnimationFromKeywords(String title, String description) {
    final text = ('$title $description').toLowerCase();
    
    // Determine animation type based on keywords
    String animationType = 'idle';
    String mood = 'neutral';
    String character = 'default';

    // Work-related tasks
    if (text.contains('work') || text.contains('meeting') || text.contains('project') || 
        text.contains('code') || text.contains('develop')) {
      animationType = 'working';
      mood = 'focused';
      character = 'worker';
    }
    // Health/Fitness tasks
    else if (text.contains('exercise') || text.contains('workout') || text.contains('gym') ||
             text.contains('run') || text.contains('fitness') || text.contains('health')) {
      animationType = 'running';
      mood = 'energetic';
      character = 'athlete';
    }
    // Learning/Study tasks
    else if (text.contains('study') || text.contains('learn') || text.contains('read') ||
             text.contains('course') || text.contains('book')) {
      animationType = 'reading';
      mood = 'curious';
      character = 'student';
    }
    // Creative tasks
    else if (text.contains('draw') || text.contains('paint') || text.contains('design') ||
             text.contains('create') || text.contains('art')) {
      animationType = 'creating';
      mood = 'inspired';
      character = 'artist';
    }
    // Cooking tasks
    else if (text.contains('cook') || text.contains('recipe') || text.contains('food') ||
             text.contains('meal')) {
      animationType = 'cooking';
      mood = 'happy';
      character = 'chef';
    }
    // Shopping tasks
    else if (text.contains('shop') || text.contains('buy') || text.contains('grocery')) {
      animationType = 'walking';
      mood = 'casual';
      character = 'shopper';
    }

    return {
      'animationType': animationType,
      'mood': mood,
      'character': character,
    };
  }

  String _mapDifficulty(String difficulty) {
    final lower = difficulty.toLowerCase();
    if (lower.contains('easy') || lower.contains('simple')) return 'Easy';
    if (lower.contains('hard') || lower.contains('difficult') || lower.contains('complex')) return 'Hard';
    return 'Medium';
  }
}

