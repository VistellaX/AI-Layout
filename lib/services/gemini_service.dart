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
    print("GEMINI_SERVICE: User prompt received: \"$userPrompt\"");
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
      print("GEMINI_SERVICE: Sending request to: $uri");
      print("GEMINI_SERVICE: Request body: ${jsonEncode(requestBody)}"); // Cuidado se tiver dados sensíveis
    } catch (e) {
      print("GEMINI_SERVICE: Error encoding request body: $e");
      // Decide se quer relançar ou continuar (provavelmente relançar)
      throw Exception("Failed to encode request body for Gemini: $e");
    }
    try {
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );
      print("GEMINI_SERVICE: Raw Status Code from Gemini: ${response.statusCode}");
      print("GEMINI_SERVICE: Raw Response Headers from Gemini: ${response.headers}");
      print("GEMINI_SERVICE: Raw Response Body from Gemini: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic responseBodyDecoded;
        try {
          responseBodyDecoded = jsonDecode(response.body);
          print("GEMINI_SERVICE: Successfully decoded raw response body.");
        } catch (e, s) {
          print("GEMINI_SERVICE: ERROR - Failed to decode raw response body from Gemini!");
          print("GEMINI_SERVICE: Raw body was: ${response.body}");
          print("GEMINI_SERVICE: Decode error: $e");
          print("GEMINI_SERVICE: Decode stack trace: $s");
          // Este é um ponto crítico. Se o corpo principal não é JSON, nada mais vai funcionar.
          throw Exception("Gemini main response body is not valid JSON. Body: ${response.body}");
        }
        if (responseBodyDecoded['candidates'] != null &&
            responseBodyDecoded['candidates'] is List &&
            (responseBodyDecoded['candidates'] as List).isNotEmpty &&
            responseBodyDecoded['candidates'][0]['content'] != null &&
            responseBodyDecoded['candidates'][0]['content']['parts'] != null &&
            responseBodyDecoded['candidates'][0]['content']['parts'] is List &&
            (responseBodyDecoded['candidates'][0]['content']['parts'] as List).isNotEmpty &&
            responseBodyDecoded['candidates'][0]['content']['parts'][0]['text'] != null) {

          String generatedJson = responseBodyDecoded['candidates'][0]['content']['parts'][0]['text'];
          print('--- Gemini Raw Response Text ---');
          print(generatedJson);
          print('--------------------------------');

          String cleanedJson = generatedJson.trim();
          const String markdownFenceJsonWithNewline = "`json\n";
          const String markdownFenceJson = "```json";
          const String markdownFenceSimpleWithNewline = "`\n";
          const String markdownFenceSimple = "```";
          const String markdownEndFenceWithNewline = "\n`";
          const String markdownEndFence = "```";
          // Check and remove Markdown fences if present
          if (cleanedJson.startsWith(markdownFenceJsonWithNewline) && cleanedJson.endsWith(markdownEndFenceWithNewline)) {
            cleanedJson = cleanedJson.substring(markdownFenceJsonWithNewline.length, cleanedJson.length - markdownEndFenceWithNewline.length).trim();
          } else if (cleanedJson.startsWith(markdownFenceJson) && cleanedJson.endsWith(markdownEndFence)) {
            cleanedJson = cleanedJson.substring(markdownFenceJson.length, cleanedJson.length - markdownEndFence.length).trim();
          } else if (cleanedJson.startsWith(markdownFenceSimpleWithNewline) && cleanedJson.endsWith(markdownEndFenceWithNewline)) {
            cleanedJson = cleanedJson.substring(markdownFenceSimpleWithNewline.length, cleanedJson.length - markdownEndFenceWithNewline.length).trim();
          } else if (cleanedJson.startsWith(markdownFenceSimple) && cleanedJson.endsWith(markdownEndFence)) {
            cleanedJson = cleanedJson.substring(markdownFenceSimple.length, cleanedJson.length - markdownEndFence.length).trim();
          }
          print('---  Cleaned JSON Attempt (after Markdown removal and trim)  ---');
          print(cleanedJson);
          print('----------------------------');
          try {
            jsonDecode(cleanedJson); // Apenas para validar o formato JSON
            print("GEMINI_SERVICE: Successfully validated cleanedJson as JSON. Returning it.");
            return cleanedJson;
          } catch (e, s) { // Este é o catch que lança a exceção que você está vendo
            print("GEMINI_SERVICE: ERROR - Cleaned JSON ('generatedJson' from parts.text) is NOT valid JSON even after trimming.");
            print("GEMINI_SERVICE: Cleaned JSON content was: $cleanedJson");
            print("GEMINI_SERVICE: Validation decode error: $e");
            print("GEMINI_SERVICE: Validation decode stack trace: $s");
            // SE ESTA EXCEÇÃO FOR LANÇADA...
            throw Exception('Gemini response is not valid JSON even after sanitization. Contents: $cleanedJson');
          }
        } else {
          print('Gemini API Unexpected Response Structure: ${response.body}');
          throw Exception('Unexpected response from Gemini API.');
        }
      } else {
        print('GEMINI_SERVICE: ERROR - Gemini API HTTP Error.');
        print('GEMINI_SERVICE: Status Code: ${response.statusCode}');
        print('GEMINI_SERVICE: Error Body: ${response.body}');
        throw Exception('Gemini API Error: ${response.statusCode}, Body: ${response.body}');
      }
    } catch (e, s) { // Catch principal do método
      print('GEMINI_SERVICE: ERROR - Exception during Gemini API call or processing.');
      print('GEMINI_SERVICE: Error Type: ${e.runtimeType}');
      print('GEMINI_SERVICE: Error: $e');
      print('GEMINI_SERVICE: StackTrace: $s');
      // Relança a exceção para que o chamador (UiStateNotifier) possa lidar com ela.
      // É importante não "engolir" a exceção aqui, a menos que você a esteja tratando e retornando um valor padrão.
      // Se a exceção já for a que você quer, ou uma que encapsula bem a informação:
      if (e.toString().contains("Gemini API Error") ||
          e.toString().contains("Gemini response is not valid JSON") ||
          e.toString().contains("Unexpected response structure")) {
        throw e; // Relança a exceção específica já formatada
      }
      // Caso contrário, encapsule-a para dar contexto
      throw Exception('Error connecting to Gemini service or processing its response: $e');
    }
  }
}