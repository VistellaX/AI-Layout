import 'ui_state.dart';
import 'package:flutter/material.dart'; // Required for Colors and ChangeNotifier.
import 'dart:convert'; // For JSON decoding.
import 'gemini_service.dart';

class ColorUtils {
  static Color getColorFromString(String colorString) {
    // Converts a string (color name or hex code) to a Color object.
    String lowerColorString = colorString.toLowerCase().trim(); // Normalize the string for easier comparison.
    switch (lowerColorString) {
    // Cases for common color names.
      case 'red':
        return Colors.red;
      case 'green':
        return Colors.green;
      case 'blue':
        return Colors.blue;
      case 'yellow':
        return Colors.yellow;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'pink':
        return Colors.pink;
      case 'black':
        return Colors.black;
      case 'white':
        return Colors.white;
      case 'grey':
      case 'gray': // Accepts both spellings for grey.
        return Colors.grey;
      default: // If not a known color name, try to process as hexadecimal.
        if (lowerColorString.startsWith('#') && (lowerColorString.length == 7 || lowerColorString.length == 9)) {
          // Check if it starts with '#' and has the correct length for a hex code (RGB or ARGB).
          try {
            String hexColor = lowerColorString.substring(1); // Remove the '#'.
            if (hexColor.length == 6) {
              hexColor = "FF" + hexColor; // Add opaque alpha (FF) if it's a 6-digit code (RGB).
            }
            if (hexColor.length == 8) { // Must be an 8-digit code (ARGB).
              return Color(int.parse(hexColor, radix: 16)); // Parse the hex to an integer and create the color.
            }
          } catch (e) {
            // If parsing fails (invalid format).
            return Colors.grey; // Return a default color in case of error.
          }
        }
        return Colors.grey; // Default color if the format is not recognized.
    }
  }
}

class UiStateNotifier extends ChangeNotifier { // Allows widgets to listen for changes in the UI state.
  UiState _uiState = UiState( //Initial UI state.
    title: 'AI Layout',
    backgroundColor: Colors.black,
    componentProperties: [
      ComponentProperty(type: 'text', text: 'Hi, you may change this layout with AI. Write commands to change this text, title, background color and add buttons.', color: Colors.white),
    ],
    isLoading: false,
    errorMessage: null,
  );

  UiState get uiState => _uiState; // Public getter to access the UI state.
  late UiState _initialState; // Stores the initial state to allow for a reset.

  final GeminiService _geminiService = GeminiService(); // Service to interact with the Gemini API.

  UiStateNotifier() {
    // Constructor: saves a copy of the initial state.
    print("UiStateNotifier CONSTRUCTOR for instance with hashCode: ${this.hashCode}");
    _initialState = _uiState.copyWith(isLoading: false, errorMessage: null); // Salva o estado inicial
  }

  Future<void> processPrompt(String prompt) async {
    // Processes the user's command (prompt).
    if (prompt.trim().isEmpty) { // Basic prompt validation.
      _uiState = _uiState.copyWith(errorMessage: "Please, write a command.");
      notifyListeners();
      return;
    }

    // Updates the state to indicate loading and clear previous errors
    _uiState = _uiState.copyWith(isLoading: true, errorMessage: null);
    notifyListeners(); // Notifies listeners about the state change (error message).


    try {
      // Calls the Gemini service to get a JSON payload based on the prompt.
      final String jsonStringFromGemini = await _geminiService.getJsonPayloadFromPrompt(prompt);

      if (jsonStringFromGemini.isNotEmpty) {
        if (jsonStringFromGemini == "[]") {
          // Handles a specific case where Gemini returns an empty list, indicating non-understanding.
          print("UI_STATE_NOTIFIER (INSTANCE ${this.hashCode}): Gemini returned []. Setting error message.");
          _uiState = _uiState.copyWith(isLoading: false, errorMessage: "I don't understand what you mean. Try another way.");
           notifyListeners();
          print("UI_STATE_NOTIFIER (INSTANCE ${this.hashCode}): Error message set and notifyListeners called. Error: ${_uiState.errorMessage}");
          return;
        }
        processJsonPayload(jsonStringFromGemini);
        _uiState = _uiState.copyWith(isLoading: false, errorMessage: null, clearErrorMessage: true); // Limpa explicitamente o erro
        notifyListeners();
      } else {
        // Case of an unexpected empty payload.
        _uiState = _uiState.copyWith(isLoading: false, errorMessage: "Received empty payload from assistant.");
        notifyListeners();
        return;
      }
    } catch (e) {
      // Handles errors during communication with Gemini or processing.
      print("Error processing prompt with Gemini: $e");
      _uiState = _uiState.copyWith(isLoading: false, errorMessage: "Error communicating with assistant: ${e.toString()}");
      notifyListeners();
    }
  }

  void processJsonPayload(String jsonString) {
    // Handles empty or uninterpretable JSON early.
    if (jsonString.trim().isEmpty || jsonString.trim() == "[]") {
      _uiState = _uiState.copyWith(errorMessage: "The assistant was unable to interpret the command.");
      notifyListeners();
      return;
    }
    try {
      // Decode the JSON string into Dart objects.
      final dynamic decodedJson = jsonDecode(jsonString);
      // Handles a list of instructions.
      if (decodedJson is List) {
        if (decodedJson.isEmpty) { // Another check for empty but valid JSON list.
          _uiState = _uiState.copyWith(errorMessage: "The assistant was unable to interpret the command.");
          notifyListeners();
          return;
        }
        // Iterate through each instruction in the list.
        for (var instruction in decodedJson) {
          if (instruction is Map<String, dynamic>) {
            try { // Apply individual instruction, catching errors per instruction.
              print("PROCESS_JSON_PAYLOAD: Applying instruction: $instruction");
              _applyInstruction(instruction);
            } catch (e, s) { // Log error for a specific instruction but continue with others.
              print("!!!!!!!! EXCEPTION INSIDE _applyInstruction (within list) !!!!!!!");
              print("Failed instruction: $instruction");
              print("Error: $e");
              print("Stack trace: $s");
            }
          } else {
            // Log if an item in the list is not a valid instruction format.
            print("PROCESS_JSON_PAYLOAD: Invalid instruction format in list: $instruction");
          }
        }
        // Handles a single instruction object.
      } else if (decodedJson is Map<String, dynamic>) {
        try { // Apply the single instruction.
          print("PROCESS_JSON_PAYLOAD: Applying single instruction: $decodedJson");
          _applyInstruction(decodedJson);
        } catch (e, s) { // If a single instruction fails, it's a more critical error.
          print("!!!!!!!! EXCEPTION INSIDE _applyInstruction (single object) !!!!!!!");
          print("Failed instruction: $decodedJson");
          print("Error: $e");
          print("Stack trace: $s");
          _uiState = _uiState.copyWith(errorMessage: "Error applying instruction: ${e.toString()}");
          throw e; // Rethrow to be caught by the outer catch, setting a general error message.
        }
      } else {
        // Handle cases where JSON is not a List or a Map.
        print("PROCESS_JSON_PAYLOAD: Unexpected JSON format. Neither List nor Map<String, dynamic>.");
        _uiState = _uiState.copyWith(errorMessage: "Unexpected response format from assistant.");
      }
    } catch (e, s) { // General error handler for JSON decoding or processing issues.
      print("Error decoding or processing JSON: $e");
      print("Stack trace: $s");
      _uiState = _uiState.copyWith(errorMessage: "Error processing wizard response.");
    }
}
  // Interprets and executes a single instruction map.
  void _applyInstruction(Map<String, dynamic> instruction) {
    // Extracts the 'action' to determine what to do.
    final String? action = instruction['action'] as String?;

    switch (action) {
      case 'update_title':
        final String? newTitle = instruction['value'] as String?;
        if (newTitle != null) updateTitle(newTitle); // Calls method to update UI state and notify.
        break;

      case 'update_background_color':
        final String? colorString = instruction['value'] as String?;
        // Converts color string to Color object and updates state.
        if (colorString != null) updateBackgroundColor(ColorUtils.getColorFromString(colorString));
        break;

      case 'add_component':
      // Extracts component data from the instruction.
        final Map<String, dynamic>? componentData = instruction['component'] as Map<String, dynamic>?;
        if (componentData != null) {
          final String? type = componentData['type'] as String?;
          final String? text = componentData['text'] as String?;
          final String? colorString = componentData['color'] as String?;

          // Validates required component data before adding.
          if (type != null && text != null) {
            addComponent(ComponentProperty(
              type: type,
              text: text,
              color: colorString != null ? ColorUtils.getColorFromString(colorString) : null,
            ));
          } else {
            print("Invalid component data for 'add_component'': type ou text ausente.");
          }
        } else {
          print("Missing component data for 'add_component''.");
        }
        break;

      case 'update_component_text':
        // Requires index and new text to update a specific component.
        final int? index = instruction['index'] as int?;
        final String? newText = instruction['text'] as String?;
        if (index != null && newText != null) {
          updateComponentText(index, newText);
        } else {
          print("Missing index or new text for 'update_component_text''.");
        }
        break;

      case 'update_component_color':
        // Requires index and new color string.
        final int? index = instruction['index'] as int?;
        final String? colorString = instruction['color'] as String?;
        if (index != null && colorString != null) {
          // Converte a string da cor para um objeto Color
          final Color newColor = ColorUtils.getColorFromString(colorString);
          updateComponentColor(index, newColor); // Chama a função que discutimos
        } else {
          print("Missing color index or string for 'update_component_color'.");
        }
        break;

      case 'remove_component':
        // Requires index to remove a specific component.
        final int? index = instruction['index'] as int?;
        if (index != null) {
          removeComponentAtIndex(index);
        } else {
          print("Missing index for 'remove_component'.");
        }
        break;

      case 'clear_components':
        clearComponents(); // Removes all components.
        break;

      default:
        // Handles any unknown actions.
        print("Unknown JSON action: $action");
    }
  }

  void updateTitle(String newTitle) {
    _uiState = _uiState.copyWith(title: newTitle); // Updates the title in the UI state.
    notifyListeners();
  }

  void updateBackgroundColor(Color newColor) {
    _uiState = _uiState.copyWith(backgroundColor: newColor); // Updates the background color.
    notifyListeners();
  }

  void addComponent(ComponentProperty component) {
    // Creates a new list with the added component to ensure immutability.
    final newList = List<ComponentProperty>.from(_uiState.componentProperties)..add(component);
    _uiState = _uiState.copyWith(componentProperties: newList);
    notifyListeners();
  }

  void updateComponentText(int index, String newText) {
    // Checks for valid index before updating.
    if (index >= 0 && index < _uiState.componentProperties.length) {
      final newList = List<ComponentProperty>.from(_uiState.componentProperties);
      newList[index].text = newText; // Directly modifies the text of the component at the given index.
      _uiState = _uiState.copyWith(componentProperties: newList); // Updates component list.
      notifyListeners();
    } else {
      print("Invalid index ($index) for updateComponentText. Maximum: ${_uiState.componentProperties.length -1}");
    }
  }

  void updateComponentColor(int index, Color newColor) {
    // Checks for valid index.
    if (index >= 0 && index < _uiState.componentProperties.length) {
      final newList = List<ComponentProperty>.from(_uiState.componentProperties);
      newList[index].color = newColor; // Directly modifies the color of the component at the given index.
      _uiState = _uiState.copyWith(componentProperties: newList); // Updates component list.
      notifyListeners();
    } else {
      print("Invalid index ($index) for updateComponentColor.");
    }
  }

  void removeComponentAtIndex(int index) {
    // Checks for valid index.
    if (index >= 0 && index < _uiState.componentProperties.length) {
      // Creates a new list excluding the component at the index.
      final newList = List<ComponentProperty>.from(_uiState.componentProperties)..removeAt(index);
      _uiState = _uiState.copyWith(componentProperties: newList); // Updates component list.
      notifyListeners();
    } else {
      print("Invalid index ($index) for removeComponentAtIndex. Maximum: ${_uiState.componentProperties.length -1}");
    }
  }

  void removeLastComponent() {
    // Checks if there are any components to remove.
    if (_uiState.componentProperties.isNotEmpty) {
      final newList = List<ComponentProperty>.from(_uiState.componentProperties)..removeLast();
      _uiState = _uiState.copyWith(componentProperties: newList); // Updates component list.
      notifyListeners();
    }
  }

  void clearComponents() {
    _uiState = _uiState.copyWith(componentProperties: []); // Replaces the list with an empty one.
    notifyListeners();
  }

  void updateInputText(String text) {
    // This method is currently empty and does not modify the state.
    // It would be used to update any user input field text if needed.
  }

  void resetUi() {
    // Reverts the UI state to the initially saved state.
    _uiState = _initialState.copyWith(isLoading: false, errorMessage: null);
    notifyListeners();
  }

  void clearErrorMessage() {
    _uiState = _uiState.copyWith(errorMessage: null); // Clears any existing error message.
    notifyListeners();
  }
}