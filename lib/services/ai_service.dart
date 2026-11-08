import 'package:flutter/foundation.dart';
import 'farmer_ai_service.dart';

class AIService {
  /// Routes prompt directly to real Vertex AI Gemini model via FarmerAiService
  static Future<String> askAI(String prompt) async {
    if (prompt.trim().isEmpty) {
      return 'Please ask a specific farming, crop pricing, or market question.';
    }

    try {
      final answer = await FarmerAiService.ask(prompt);
      if (answer.trim().isNotEmpty) {
        return answer;
      }
    } catch (e) {
      debugPrint('[AIService] Vertex AI call error: $e');
    }

    return 'KisanAI Market Advisory is analyzing live data. Please check your network connection and retry.';
  }
}
