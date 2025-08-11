import 'package:ai_layout/services/ui_state_notifier.dart';
import 'package:ai_layout/services/ui_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _promptController.addListener(() {
      final uiStateNotifier = context.read<UiStateNotifier>();
      if (_promptController.text.isNotEmpty && uiStateNotifier.uiState.errorMessage != null) {
        uiStateNotifier.clearErrorMessage();
      }
    });
  }

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  void _submitPrompt() {
    final prompt = _promptController.text;
    if (prompt.isNotEmpty) {
      context.read<UiStateNotifier>().processPrompt(prompt);
    } else {
      // Mostrar um erro se o prompt estiver vazio, se não for tratado no Notifier
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please, write a command.'), backgroundColor: Colors.orange),
      );
    }
  }

  Color getTextColorForBackground(Color backgroundColor) {
    // Calculates the luminance of the background color.
    // The formula for perceived luminance is Y = 0.299*R + 0.587*G + 0.114*B
    // Colors with luminance < 0.5 are generally considered dark.
    // Normalizes RGB values to the range 0-1.
    double luminance = (0.299 * backgroundColor.r / 255) +
        (0.587 * backgroundColor.g / 255) +
        (0.114 * backgroundColor.b / 255);

    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final uiStateNotifier = context.watch<UiStateNotifier>();
    final uiState = uiStateNotifier.uiState;
    final Color textFieldTextColor = getTextColorForBackground(uiState.backgroundColor);

    if (uiState.errorMessage != null && !uiState.isLoading) { // Não mostrar erro se estiver carregando novo
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).removeCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uiState.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
        context.read<UiStateNotifier>().clearErrorMessage();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(uiState.title),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: uiState.isLoading ? null : () {
              // Use context.read to call methods without rebuilding when the method is called
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
            // List of dynamic components
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
                        onPressed: () {},
                        child: Text(component.text),
                        style: ElevatedButton.styleFrom(backgroundColor: component.color),
                      ),
                    );
                  }
                  return SizedBox.shrink(); // Unknown component
                },
              ),
            ),
            if (uiState.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(textFieldTextColor),
                )),
              ),
            // Barra de entrada
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      style: TextStyle(color: textFieldTextColor),
                      decoration: InputDecoration(
                        hintText: "Write command here...",
                        hintStyle: TextStyle(color: textFieldTextColor.withValues()), // Um pouco mais sutil
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: textFieldTextColor.withValues()),
                        ),
                        enabledBorder: OutlineInputBorder( // Edge when enabled
                          borderSide: BorderSide(color: textFieldTextColor.withValues()),
                        ),
                        focusedBorder: OutlineInputBorder( // Edge when focused
                          borderSide: BorderSide(color: textFieldTextColor, width: 2.0),
                        ),
                      ),
                      enabled: !uiState.isLoading,
                      onSubmitted: uiState.isLoading ? null : (value) { // Allows you to send with Enter
                        _submitPrompt();
                      },
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textFieldTextColor, // Button with text color
                      foregroundColor: uiState.backgroundColor, // Button text with background color
                    ).copyWith(),
                    child: uiState.isLoading ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(uiState.backgroundColor))) : Text('Send'),
                    onPressed: uiState.isLoading ? null : _submitPrompt,
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