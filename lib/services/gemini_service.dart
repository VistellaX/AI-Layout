import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  final String? apiKey = dotenv.env['GEMINI_API_KEY'];
  final String? apiUrl = dotenv.env['GEMINI_API_URL'];

  static const String _systemInstruction = """
You are a wizard helping to modify a Flutter app's user interface.
The user provides a natural language command. Your task is to parse this command
and generate a list of actions in JSON format that the app can understand.
The response MUST be ONLY the JSON array, with no additional text or explanation before or after.

Valid JSON actions and their parameters:
1.  `{"action": "update_title", "value": "NEW_TITLE_STRING"}`
2.  `{"action": "update_background_color", "value": "COLOR_NAME_OR_HEX_STRING"}`
    (Common colors: red, green, blue, yellow, orange, purple, pink, black, white, grey/gray. Hex: #RRGGBB)
3.  `{"action": "add_component", "component": {"type": "STRING_COMPONENT_TYPE", "text": "TEXT_COMPONENT_STRING", "color": "COLOR_NAME_OR_HEX_STRING_OPTIONAL"}}`
    (Valid component types: 'text', 'button')
4.  `{"action": "update_component_text", "index": NUMERICAL_INDEX_BASE_0, "text": "NEW_TEXT_STRING"}`
5.  `{"action": "update_component_color", "index": NUMERICAL_INDEX_BASE_0, "color": "COLOR_NAME_OR_HEX_STRING"}`
5.  `{"action": "remove_component", "index": NUMERICAL_INDEX_BASE_0}`
6.  `{"action": "clear_components"}`

Interaction Examples:
User: Change the title to 'My Awesome App' and the background to green.
You Return:
[
  {"action": "update_title", "value": "My Amazing App"},
  {"action": "update_background_color", "value": "green"}
]

User: Add a blue button with the text 'Click Here'.
You Return:
[
  {"action": "add_component", "component": {"type": "button", "text": "Click here", "color": "blue"}}
]

User: Clear screen.
You Return:
[
  {"action": "clear_components"}
]

User: Put 'Hello World' in the first item.
You Return:
[
  {"action": "update_component_text", "index": 0, "text": "Hello World"}
]

User: Change the color of the 'Hello World' text to green.
You Return:
[
  {"action": "update_component_color", "index": 0, "color": "green"}
]

If the command is unclear or cannot be translated into JSON actions, return an empty JSON array: `[]`.
YOUR RESPONSE SHOULD BE JUST THE JSON ARRAY. DO NOT wrap the JSON in Markdown code blocks ().
DO NOT include any explanatory text before or after the JSON array. The response must begin directly with `[` and end with `]`.
""";
  Future<String> getJsonPayloadFromPrompt(String userPrompt) async {
    final Uri uri = Uri.parse(apiUrl!);

    //List<Map<String, dynamic>> localMsgs = [...msgs];
    // insere o system prompt no inicio da conversa
    final Map<String, dynamic> requestBody = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": _systemInstruction},
            {"text": "Comando do Usuário: ${userPrompt}"}
          ]
        }
      ],
      // ... generationConfig e safetySettings ...
    };
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseBody = jsonDecode(response.body);
        if (responseBody['candidates'] != null &&
            responseBody['candidates'] is List &&
            (responseBody['candidates'] as List).isNotEmpty &&
            responseBody['candidates'][0]['content'] != null &&
            responseBody['candidates'][0]['content']['parts'] != null &&
            responseBody['candidates'][0]['content']['parts'] is List &&
            (responseBody['candidates'][0]['content']['parts'] as List).isNotEmpty &&
            responseBody['candidates'][0]['content']['parts'][0]['text'] != null) {

          String generatedJson = responseBody['candidates'][0]['content']['parts'][0]['text'];
          print('--- Gemini Raw Response Text ---');
          print(generatedJson);
          print('--------------------------------');

          String cleanedJson = generatedJson.trim();
          print('--- Cleaned JSON Attempt ---');
          print(cleanedJson);
          print('----------------------------');
          try {
            jsonDecode(cleanedJson); // Apenas para validar o formato JSON
            return cleanedJson;
          } catch (e) {
            print('Gemini returned text that is not valid JSON even after cleaning: $cleanedJson');
            // SE ESTA EXCEÇÃO FOR LANÇADA...
            throw Exception('Gemini response is not valid JSON even after sanitization. Contents: $cleanedJson');
          }
        } else {
          print('Gemini API Unexpected Response Structure: ${response.body}');
          throw Exception('Unexpected response from Gemini API.');
        }
      } else {
        print('Gemini API Error: ${response.statusCode}');
        print('Error Body: ${response.body}');
        throw Exception('Gemini API Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error calling Gemini API: $e');
      throw Exception('Error connecting to Gemini service: $e');
    }
  }
}