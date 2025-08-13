import 'ui_state.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'gemini_service.dart';

class ColorUtils {
  static Color getColorFromString(String colorString) {
    String lowerColorString = colorString.toLowerCase().trim();
    switch (lowerColorString) {
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
      case 'gray':
        return Colors.grey;
      default:
        if (lowerColorString.startsWith('#') && (lowerColorString.length == 7 || lowerColorString.length == 9)) {
          try {
            String hexColor = lowerColorString.substring(1); // Remove #
            if (hexColor.length == 6) {
              hexColor = "FF" + hexColor; // Add alpha if missing
            }
            if (hexColor.length == 8) {
              return Color(int.parse(hexColor, radix: 16));
            }
          } catch (e) {
            return Colors.grey; // Cor padrão em caso de erro de parsing
          }
        }
        return Colors.grey; // Cor padrão para nomes não reconhecidos
    }
  }
}

class UiStateNotifier extends ChangeNotifier {
  UiState _uiState = UiState(
    title: 'AI Layout',
    backgroundColor: Colors.black,
    componentProperties: [
      ComponentProperty(type: 'text', text: 'Hi, you may change this layout with AI. Write commands to change this text, title, background color and add buttons.', color: Colors.white),
    ],
    isLoading: false,
    errorMessage: null,
  );

  UiState get uiState => _uiState;
  late UiState _initialState; // Para o reset

  final GeminiService _geminiService = GeminiService();

  UiStateNotifier() {
    print("UiStateNotifier CONSTRUCTOR for instance with hashCode: ${this.hashCode}");
    _initialState = _uiState.copyWith(isLoading: false, errorMessage: null); // Salva o estado inicial
  }

  Future<void> processPrompt(String prompt) async {
    if (prompt.trim().isEmpty) {
      _uiState = _uiState.copyWith(errorMessage: "Please, write a command.");
      notifyListeners();
      return;
    }

    // Updates the state to indicate loading and clear previous errors
    _uiState = _uiState.copyWith(isLoading: true, errorMessage: null);
    notifyListeners();

    try {
      final String jsonStringFromGemini = await _geminiService.getJsonPayloadFromPrompt(prompt);

      if (jsonStringFromGemini.isNotEmpty) {
        if (jsonStringFromGemini == "[]") {
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
        // Caso o GeminiService retorne uma string vazia por algum motivo inesperado
        _uiState = _uiState.copyWith(isLoading: false, errorMessage: "Received empty payload from assistant.");
        notifyListeners();
        return;
      }
    } catch (e) {
      print("Error processing prompt with Gemini: $e");
      _uiState = _uiState.copyWith(isLoading: false, errorMessage: "Error communicating with assistant: ${e.toString()}");
      notifyListeners();
    }
  }

  void processJsonPayload(String jsonString) {
    if (jsonString.trim().isEmpty || jsonString.trim() == "[]") {
      _uiState = _uiState.copyWith(errorMessage: "The assistant was unable to interpret the command.");
      notifyListeners(); // Certifique-se de notificar se o estado for alterado
      return;
    }
    try {
      final dynamic decodedJson = jsonDecode(jsonString);

      if (decodedJson is List) {
        if (decodedJson.isEmpty) {
          _uiState = _uiState.copyWith(errorMessage: "The assistant was unable to interpret the command.");
          notifyListeners();
          return;
        }
        for (var instruction in decodedJson) {
          if (instruction is Map<String, dynamic>) {
            try { // <--- Início do try-catch para _applyInstruction
              print("PROCESS_JSON_PAYLOAD: Applying instruction: $instruction");
              _applyInstruction(instruction);
            } catch (e, s) { // <--- Catch para _applyInstruction
              print("!!!!!!!! EXCEPTION INSIDE _applyInstruction (within list) !!!!!!!");
              print("Failed instruction: $instruction");
              print("Error: $e");
              print("Stack trace: $s");
              // Decida se quer definir um erro geral aqui ou apenas logar e continuar
              // Ex: _uiState = _uiState.copyWith(errorMessage: "Error applying one of the instructions: $e");
              // notifyListeners();
              // Se você definir um erro aqui e houver múltiplas instruções, o último erro prevalecerá.
            }
          } else {
            print("PROCESS_JSON_PAYLOAD: Invalid instruction format in list: $instruction");
            // Você pode querer definir um erro aqui também
          }
        }
      } else if (decodedJson is Map<String, dynamic>) {
        try { // <--- Início do try-catch para _applyInstruction (caso seja um objeto único)
          print("PROCESS_JSON_PAYLOAD: Applying single instruction: $decodedJson");
          _applyInstruction(decodedJson);
        } catch (e, s) { // <--- Catch para _applyInstruction
          print("!!!!!!!! EXCEPTION INSIDE _applyInstruction (single object) !!!!!!!");
          print("Failed instruction: $decodedJson");
          print("Error: $e");
          print("Stack trace: $s");
          // Defina o erro aqui, pois é uma única instrução
          _uiState = _uiState.copyWith(errorMessage: "Error applying instruction: ${e.toString()}");
          throw e; // Relança a exceção para ser pega pelo catch abaixo.
        }
      } else {
        print("PROCESS_JSON_PAYLOAD: Unexpected JSON format. Neither List nor Map<String, dynamic>.");
        _uiState = _uiState.copyWith(errorMessage: "Unexpected response format from assistant.");
        // notifyListeners(); // Deixe processPrompt lidar com a notificação
      }
    } catch (e, s) {
      print("Error decoding or processing JSON: $e");
      print("Stack trace: $s");
      _uiState = _uiState.copyWith(errorMessage: "Error processing wizard response.");
    }
}

  void _applyInstruction(Map<String, dynamic> instruction) {
    final String? action = instruction['action'] as String?;

    switch (action) {
      case 'update_title':
        final String? newTitle = instruction['value'] as String?;
        if (newTitle != null) updateTitle(newTitle);
        break;

      case 'update_background_color':
        final String? colorString = instruction['value'] as String?;
        if (colorString != null) updateBackgroundColor(ColorUtils.getColorFromString(colorString));
        break;

      case 'add_component':
        final Map<String, dynamic>? componentData = instruction['component'] as Map<String, dynamic>?;
        if (componentData != null) {
          final String? type = componentData['type'] as String?;
          final String? text = componentData['text'] as String?;
          final String? colorString = componentData['color'] as String?;

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
        final int? index = instruction['index'] as int?;
        final String? newText = instruction['text'] as String?;
        if (index != null && newText != null) {
          updateComponentText(index, newText);
        } else {
          print("Missing index or new text for 'update_component_text''.");
        }
        break;

    // Dentro de _applyInstruction no UiStateNotifier
      case 'update_component_color':
        final int? index = instruction['index'] as int?;
        final String? colorString = instruction['color'] as String?;
        if (index != null && colorString != null) {
          // Converte a string da cor para um objeto Color
          final Color newColor = ColorUtils.getColorFromString(colorString);
          updateComponentColor(index, newColor); // Chama a função que discutimos
        } else {
          print("Missing color index or string for 'update_component_color'.");
          // stateChanged = false; // Se você estiver rastreando isso
        }
        break;

      case 'remove_component':
        final int? index = instruction['index'] as int?;
        if (index != null) {
          removeComponentAtIndex(index);
        } else {
          print("Missing index for 'remove_component'.");
        }
        break;

      case 'clear_components':
        clearComponents();
        break;

      default:
        print("Unknown JSON action: $action");
    }
  }

  void updateTitle(String newTitle) {
    _uiState = _uiState.copyWith(title: newTitle);
    notifyListeners();
  }

  void updateBackgroundColor(Color newColor) {
    _uiState = _uiState.copyWith(backgroundColor: newColor);
    notifyListeners();
  }

  void addComponent(ComponentProperty component) {
    final newList = List<ComponentProperty>.from(_uiState.componentProperties)..add(component);
    _uiState = _uiState.copyWith(componentProperties: newList);
    notifyListeners();
  }

  void updateComponentText(int index, String newText) {
    if (index >= 0 && index < _uiState.componentProperties.length) {
      final newList = List<ComponentProperty>.from(_uiState.componentProperties);
      newList[index].text = newText;
      _uiState = _uiState.copyWith(componentProperties: newList);
      notifyListeners();
    } else {
      print("Invalid index ($index) for updateComponentText. Maximum: ${_uiState.componentProperties.length -1}");
    }
  }

  void updateComponentColor(int index, Color newColor) {
    if (index >= 0 && index < _uiState.componentProperties.length) {
      final newList = List<ComponentProperty>.from(_uiState.componentProperties);
      newList[index].color = newColor;

      _uiState = _uiState.copyWith(componentProperties: newList);
      notifyListeners();
    } else {
      print("Invalid index ($index) for updateComponentColor.");
    }
  }

  void removeComponentAtIndex(int index) {
    if (index >= 0 && index < _uiState.componentProperties.length) {
      final newList = List<ComponentProperty>.from(_uiState.componentProperties)..removeAt(index);
      _uiState = _uiState.copyWith(componentProperties: newList);
      notifyListeners();
    } else {
      print("Invalid index ($index) for removeComponentAtIndex. Maximum: ${_uiState.componentProperties.length -1}");
    }
  }

  void removeLastComponent() {
    if (_uiState.componentProperties.isNotEmpty) {
      final newList = List<ComponentProperty>.from(_uiState.componentProperties)..removeLast();
      _uiState = _uiState.copyWith(componentProperties: newList);
      notifyListeners();
    }
  }

  void clearComponents() {
    _uiState = _uiState.copyWith(componentProperties: []);
    notifyListeners();
  }

  void updateInputText(String text) {
    
  }

  void resetUi() {
    _uiState = _initialState.copyWith(isLoading: false, errorMessage: null);
    notifyListeners();
  }

  void clearErrorMessage() {
    _uiState = _uiState.copyWith(errorMessage: null);
    notifyListeners();
  }
}