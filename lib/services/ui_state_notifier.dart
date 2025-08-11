import 'ui_state.dart';
import 'package:flutter/material.dart';

class UiStateNotifier extends ChangeNotifier {
  UiState _uiState = UiState(
    title: 'Título Inicial',
    backgroundColor: Colors.grey,
    componentProperties: [
      ComponentProperty(type: 'text', text: 'Componente Inicial 1'),
    ],
  );

  UiState get uiState => _uiState;
  late UiState _initialState; // Para o reset

  UiStateNotifier() {
    _initialState = _uiState.copyWith(); // Salva o estado inicial
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
    }
  }

  void removeLastComponent() {
    if (_uiState.componentProperties.isNotEmpty) {
      final newList = List<ComponentProperty>.from(_uiState.componentProperties)..removeLast();
      _uiState = _uiState.copyWith(componentProperties: newList);
      notifyListeners();
    }
  }

  void updateInputText(String text) {
    
  }

  void resetUi() {
    _uiState = _initialState.copyWith(); // Restaura ao estado inicial salvo
    notifyListeners();
  }

  void processPrompt(String prompt) {
    final sanitizedPrompt = prompt.trim().toLowerCase();

    if (sanitizedPrompt.startsWith('change title to ')) {
      final newTitle = sanitizedPrompt.substring('change title to '.length).trim();
      if (newTitle.isNotEmpty) {
        updateTitle(newTitle);
      }
    } else if (sanitizedPrompt.startsWith('change background color to ')) {
      final colorName = sanitizedPrompt.substring('change background color to '.length).trim();
      Color? newColor;
      switch (colorName) {
        case 'red':
          newColor = Colors.red;
          break;
        case 'green':
          newColor = Colors.green;
          break;
        case 'blue':
          newColor = Colors.blue;
          break;
        case 'yellow':
          newColor = Colors.yellow;
          break;
        case 'orange':
          newColor = Colors.orange;
          break;
      }
      if (newColor != null) {
        updateBackgroundColor(newColor);
      }
    } else if (sanitizedPrompt.startsWith('add component')) {
      final componentText = sanitizedPrompt.substring('add component'.length).trim();
      addComponent(ComponentProperty(type: 'text', text: componentText.isNotEmpty ? componentText : 'New Component'));
    } else if (sanitizedPrompt.startsWith('remove last component')) {
      removeLastComponent();
    } else if (sanitizedPrompt.startsWith('reset ui')) {
      resetUi();
    } else {
      print('comando não reconhecido: $sanitizedPrompt');
    }
  }
}