import 'package:flutter/material.dart';
class UiState {
  String title;
  Color backgroundColor;
  List<ComponentProperty> componentProperties;
  String inputBarText;

  UiState({
    required this.title,
    required this.backgroundColor,
    this.componentProperties = const [],
    this.inputBarText = '',
  });

  // Método para criar uma cópia com valores atualizados (imutabilidade é uma boa prática)
  UiState copyWith({
    String? title,
    Color? backgroundColor,
    List<ComponentProperty>? componentProperties,
    String? inputBarText,
  }) {
    return UiState(
      title: title ?? this.title,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      componentProperties: componentProperties ?? this.componentProperties,
      inputBarText: inputBarText ?? this.inputBarText,
    );
  }
}

class ComponentProperty {
  final String type; // 'text', 'button', etc.
  String text;
  Color? color; // Opcional

  ComponentProperty({required this.type, required this.text, this.color});
}
        