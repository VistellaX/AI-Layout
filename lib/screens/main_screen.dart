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
    //final uiStateNotifier = context.read<UiStateNotifier>();
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
    double luminance = (0.299 * backgroundColor.red +
        0.587 * backgroundColor.green  +
        0.114 * backgroundColor.blue) / 255;

    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    final uiStateNotifier = context.watch<UiStateNotifier>();
    print("MAIN_SCREEN BUILD using UiStateNotifier instance with hashCode: ${uiStateNotifier.hashCode}");
    final UiState currentUiState = uiStateNotifier.uiState;
    final Color textFieldTextColor = getTextColorForBackground(currentUiState.backgroundColor);
    print("MAIN_SCREEN BUILD: isLoading: ${currentUiState.isLoading}, errorMessage: ${currentUiState.errorMessage}");
    if (currentUiState.errorMessage != null && !currentUiState.isLoading) { // Não mostrar erro se estiver carregando novo
      print("MAIN_SCREEN: Condition MET for SnackBar. Error: ${currentUiState.errorMessage}");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final latestUiState = context.read<UiStateNotifier>().uiState; // Use .read aqui dentro do callback
        print("MAIN_SCREEN: addPostFrameCallback EXECUTING. Error from latestUiState: ${latestUiState.errorMessage}, context valid: ${context.mounted}");
        if (context.mounted && latestUiState.errorMessage != null) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(latestUiState.errorMessage!),
              backgroundColor: Colors.redAccent,
              duration: Duration(seconds: 4),
            ),
          );
          print("MAIN_SCREEN: showSnackBar CALLED with error: ${latestUiState.errorMessage}.");
        } else {
          print("MAIN_SCREEN: Context NOT MOUNTED or errorMessage became null in addPostFrameCallback. Mounted: ${context.mounted}, Error: ${latestUiState.errorMessage}");
        }
        //context.read<UiStateNotifier>().clearErrorMessage();
      });
    } else {
      if (currentUiState.errorMessage != null) { // Log se o erro existe mas isLoading é true
        print("MAIN_SCREEN: Condition NOT MET for SnackBar because isLoading is ${currentUiState.isLoading}. Error: ${currentUiState.errorMessage}");
      } else if (!currentUiState.isLoading){
        print("MAIN_SCREEN: Condition NOT MET for SnackBar because errorMessage is null. isLoading: ${currentUiState.isLoading}");
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUiState.title),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: currentUiState.isLoading ? null : () {
              // Use context.read to call methods without rebuilding when the method is called
              context.read<UiStateNotifier>().resetUi();
              _promptController.clear();
            },
          ),
        ],
      ),
      backgroundColor: currentUiState.backgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // List of dynamic components
            Expanded(
              child: ListView.builder(
                itemCount: currentUiState.componentProperties.length,
                itemBuilder: (context, index) {
                  final component = currentUiState.componentProperties[index];
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
            if (currentUiState.isLoading)
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
                        hintStyle: TextStyle(color: textFieldTextColor.withOpacity(0.7)), // Um pouco mais sutil
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: textFieldTextColor.withOpacity(0.7)),
                        ),
                        enabledBorder: OutlineInputBorder( // Edge when enabled
                          borderSide: BorderSide(color: textFieldTextColor.withOpacity(0.7)),
                        ),
                        focusedBorder: OutlineInputBorder( // Edge when focused
                          borderSide: BorderSide(color: textFieldTextColor, width: 2.0),
                        ),
                      ),
                      enabled: !currentUiState.isLoading,
                      onSubmitted: currentUiState.isLoading ? null : (value) {
                        _submitPrompt();
                      }
                    ),
                  ),
                  SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textFieldTextColor, // Button with text color
                      foregroundColor: currentUiState.backgroundColor, // Button text with background color
                    ).copyWith(),
                    child: currentUiState.isLoading ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(currentUiState.backgroundColor))) : Text('Send'),
                    onPressed: currentUiState.isLoading ? null : _submitPrompt,
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