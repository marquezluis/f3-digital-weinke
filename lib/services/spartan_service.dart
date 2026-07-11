// lib/services/spartan_service.dart
// The AI Brain of the Digital Weinke, powered by Google Gemini.

import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/workout_plan.dart';

class SpartanService {
  // Singleton instance
  static final SpartanService instance = SpartanService._internal();

  GenerativeModel? _model;
  ChatSession? _chatSession;

  SpartanService._internal();

  /// Initialize the service with the API key from settings.
  void init(String apiKey) {
    if (apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-3.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(
          'You are "Spartan", a rugged, encouraging, and slightly sarcastic AI assistant '
          'built to help F3 Nation workout leaders (called "Qs"). You speak using F3 '
          'terminology (PAX, Gloom, Beatdown, Mumblechatter, HC, FNG, etc.). Keep answers concise and actionable.'
        ),
      );
      _chatSession = _model!.startChat();
    } else {
      _model = null;
      _chatSession = null;
    }
  }

  /// Returns true if the Gemini API key was provided at build time.
  bool get isConfigured => _model != null;

  // ── 1. The "Co-Q" Chatbot & Gloom Weather Prep ─────────────────────────────
  
  /// Sends a message to the ongoing Spartan chat session.
  Future<String> askSpartan(String message) async {
    if (!isConfigured || _chatSession == null) return 'Spartan is resting. (API key not configured)';
    
    try {
      final response = await _chatSession!.sendMessage(Content.text(message));
      return response.text ?? 'Spartan is silently staring at you...';
    } catch (e) {
      return 'Spartan is out of comms. Check your cell service in the Gloom.';
    }
  }

  // ── 2. The FNG Naming Engine ───────────────────────────────────────────────
  
  /// Generates 5 F3 names based on facts about the new guy.
  Future<String> generateFNGNames(String facts) async {
    if (!isConfigured || _model == null) return 'Spartan is resting. (API key not configured)';

    final prompt = '''
A Friendly New Guy (FNG) just finished his first F3 beatdown. It is a sacred tradition to give him a nickname.
Here are the facts we learned about him during the Circle of Trust: "$facts"

Generate 5 hilarious, creative F3-style name options for him. 
For each name, provide a 1-sentence witty explanation of why it fits. Do not use generic names.
''';
    
    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Error generating names.';
    } catch (e) {
      return 'Could not connect to the Spartan Naming Engine.';
    }
  }

  // ── 3. The Auto-Backblast Scribe ───────────────────────────────────────────
  
  /// Generates a highly entertaining Slack post summarizing the workout.
  Future<String> generateBackblast(WorkoutPlan plan, String notes, String ao, String qName) async {
    if (!isConfigured || _model == null) return 'Spartan is resting. (API key not configured)';

    final exerciseList = plan.allExercises.map((e) => e.name).join(', ');
    
    final prompt = '''
Write a highly entertaining "Backblast" (a summary of an F3 workout) formatted for Slack.

Workout details:
- AO (Location): $ao
- Q (Leader): $qName
- Exercises performed: $exerciseList
- Q's Notes/Observations: $notes

Make it rugged, use F3 slang (mumblechatter, smoked, HIMs, etc.), include appropriate emojis, 
and make the tone sound like a tough but proud leader.
''';
    
    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Error generating backblast.';
    } catch (e) {
      return 'Spartan dropped his pen. Try again later.';
    }
  }

  // ── 4. Beatdown Auditor (Pre-Workout) ──────────────────────────────────────
  
  /// Analyzes a drafted Weinke for safety and flow.
  Future<String> auditBeatdown(WorkoutPlan plan) async {
    if (!isConfigured || _model == null) return 'Spartan is resting. (API key not configured)';

    final exerciseList = plan.allExercises.map((e) => e.name).join(', ');
    
    final prompt = '''
I am preparing to lead a 50-minute F3 bootcamp. Here is my list of exercises: $exerciseList.

Act as a veteran F3 Q and audit this list. 
1. Check for unsafe fatigue stacking (e.g., too many shoulder/push exercises back-to-back).
2. Check if there is enough leg and core balance.
3. Give me 2 short, actionable warnings or swap suggestions to make this a better beatdown.
Keep the response under 4 sentences.
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? 'Beatdown looks fine, but Spartan is suspicious.';
    } catch (e) {
      return 'Audit failed. Trust your gut, Q.';
    }
  }
}