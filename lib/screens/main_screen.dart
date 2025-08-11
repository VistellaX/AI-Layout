import 'package:ai_layout/services/ui_state_notifier.dart';
import 'package:ai_layout/services/ui_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _promptController = TextEditingController();

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Ouve as mudanças no UiStateNotifier
    final uiStateNotifier = context.watch<UiStateNotifier>();
    final uiState = uiStateNotifier.uiState;

    return Scaffold(
      appBar: AppBar(
        title: Text(uiState.title),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              // Usa context.read para chamar métodos sem reconstruir quando o método é chamado
              context.read<UiStateNotifier>().resetUi();
              _promptController.clear();
            },
          ),
        ],
      ),
      backgroundColor: uiState.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Lista de componentes dinâmicos
            Expanded(
              child: ListView.builder(
                itemCount: uiState.componentProperties.length,
                itemBuilder: (context, index) {
                  final component = uiState.componentProperties[index];
                  if (component.type == 'text') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(component.text, style: TextStyle(fontSize: 18, color: component.color)),
                    );
                  } else if (component.type == 'button') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: () {}, // Ação do botão pode ser definida depois
                        child: Text(component.text),
                        style: ElevatedButton.styleFrom(backgroundColor: component.color),
                      ),
                    );
                  }
                  return SizedBox.shrink(); // Componente desconhecido
                },
              ),
            ),
            // Barra de entrada
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      decoration: InputDecoration(
                        hintText: "Write prompt...",
                        border: OutlineInputBorder(),
                      ),
                      onSubmitted: (value) { // Permite enviar com Enter
                        if (value.isNotEmpty) {
                          context.read<UiStateNotifier>().processPrompt(value);
                          _promptController.clear();
                        }
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    child: Text('Send'),
                    onPressed: () {
                      final prompt = _promptController.text;
                      if (prompt.isNotEmpty) {
                        context.read<UiStateNotifier>().processPrompt(prompt);
                        _promptController.clear();
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}