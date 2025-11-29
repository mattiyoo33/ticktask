# AI Features Setup Guide

This document explains how to set up and use the AI features in TickTask.

## Features Added

### 1. Pixel Art Animation Widget (Dashboard)
- Displays animated pixel art characters based on active tasks
- Automatically detects task type from title/description
- Shows different animations for work, fitness, learning, creative, cooking, and shopping tasks
- Pokemon-style pixel art animations

### 2. AI Task Generator (Task Creation Screen)
- Allows users to type a natural language prompt
- AI generates task details (title, description, difficulty, category)
- Automatically fills the task creation form

## Setup Instructions

### Step 1: Add AI API Key to env.json

Add your AI API key to `env.json`:

```json
{
  "SUPABASE_URL": "your-supabase-url",
  "SUPABASE_ANON_KEY": "your-supabase-key",
  "OPENAI_API_KEY": "your-actual-openai-api-key-here",
  "GOOGLE_WEB_CLIENT_ID": "your-google-client-id"
}
```

### Step 2: AI Service Configuration

The `AIService` class is located in `lib/services/ai_service.dart`.

**Current Configuration:**
- ✅ Uses OpenAI Chat Completions API
- ✅ API URL: `https://api.openai.com/v1/chat/completions`
- ✅ Model: `gpt-4o-mini` (cost-effective, can be changed to `gpt-3.5-turbo` or `gpt-4`)
- ✅ Reads API key from `AppConfig.openAiApiKey`

**How It Works:**

The service uses OpenAI's Chat Completions API to generate tasks. It sends a prompt and receives a JSON response with task details.

**Example API Call:**
- **Endpoint**: `POST https://api.openai.com/v1/chat/completions`
- **Headers**: 
  - `Content-Type: application/json`
  - `Authorization: Bearer YOUR_OPENAI_API_KEY`
- **Body**:
```json
{
  "model": "gpt-4o-mini",
  "messages": [
    {
      "role": "system",
      "content": "You are a helpful task management assistant..."
    },
    {
      "role": "user",
      "content": "Create a task from this prompt: 'Workout for 30 minutes every morning'..."
    }
  ],
  "temperature": 0.7,
  "max_tokens": 300
}
```

**Response Format:**
The AI returns JSON in this format:
```json
{
  "title": "Morning Workout",
  "description": "30 minutes of exercise to start your day",
  "difficulty": "Medium",
  "category": "Health",
  "estimated_duration": 30,
  "suggested_due_date": "2024-01-15"
}
```

**Animation Detection:**
- Currently uses fast keyword-based detection (works offline, no API calls)
- Optional: Uncomment code in `getAnimationForTask()` to use OpenAI for animation detection

## Fallback Behavior

If the AI API is not configured or unavailable:
- **Task Generation**: Shows an error message
- **Animation Detection**: Uses keyword-based detection (works offline)

## Keyword-Based Animation Detection

The fallback system detects task types from keywords:

- **Work tasks**: work, meeting, project, code, develop → `working` animation
- **Fitness tasks**: exercise, workout, gym, run, fitness → `running` animation
- **Learning tasks**: study, learn, read, course, book → `reading` animation
- **Creative tasks**: draw, paint, design, create, art → `creating` animation
- **Cooking tasks**: cook, recipe, food, meal → `cooking` animation
- **Shopping tasks**: shop, buy, grocery → `walking` animation

## Customization

### Pixel Art Widget
- Location: `lib/presentation/home_dashboard/widgets/pixel_art_animation_widget.dart`
- You can replace the placeholder pixel art with actual sprite animations
- Add your own pixel art assets to `assets/images/` and update the widget

### AI Service
- Location: `lib/services/ai_service.dart`
- Modify prompt templates, response parsing, or add new AI features

## Testing

1. **Without API Key**: The animation widget will work with keyword detection
2. **With API Key**: Both features will use AI when configured
3. **Error Handling**: Both features gracefully handle API errors

## Next Steps

1. Add your AI API key to `env.json`
2. Test task generation on the task creation screen
3. Check the dashboard to see pixel art animations for active tasks
4. Customize animations and AI prompts as needed

