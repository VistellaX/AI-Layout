import 'package:ai_layout/services/ui_state_notifier.dart';
import 'package:ai_layout/services/ui_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';// Used to access UiStateNotifier.

// Defines the main screen widget, which is stateful to manage dynamic content.
class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // Controller for the text input field where users type commands.
  final _promptController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Example of how one might access the notifier if needed in initState (currently commented out).
    // final uiStateNotifier = context.read<UiStateNotifier>();
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the widget tree.
    _promptController.dispose();
    super.dispose();
  }
  // Called when the user submits a command.
  void _submitPrompt() {
    final prompt = _promptController.text;
    if (prompt.isNotEmpty) {
      // Accesses UiStateNotifier via Provider to process the command.
      // context.read is used because this action does not need to rebuild this widget.
      context.read<UiStateNotifier>().processPrompt(prompt);
    } else {
      // Shows an orange SnackBar if the prompt is empty (client-side validation).
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please, write a command.'), backgroundColor: Colors.orange),
      );
    }
  }
  // Determines appropriate text color (black or white) based on background luminance.
  Color getTextColorForBackground(Color backgroundColor) {
    // Calculates perceived luminance.
    double luminance = (0.299 * backgroundColor.red +
        0.587 * backgroundColor.green  +
        0.114 * backgroundColor.blue) / 255;
    // Returns black for light backgrounds, white for dark backgrounds.
    return luminance > 0.5 ? Colors.black : Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    // Listens to UiStateNotifier for state changes to rebuild the UI.
    // context.watch ensures this widget rebuilds when UiStateNotifier calls notifyListeners.
    final uiStateNotifier = context.watch<UiStateNotifier>();
    print("MAIN_SCREEN BUILD using UiStateNotifier instance with hashCode: ${uiStateNotifier.hashCode}");
    final UiState currentUiState = uiStateNotifier.uiState; // Current UI state.
    // Calculates text color for input field based on the dynamic background color.
    final Color textFieldTextColor = getTextColorForBackground(currentUiState.backgroundColor);
    print("MAIN_SCREEN BUILD: isLoading: ${currentUiState.isLoading}, errorMessage: ${currentUiState.errorMessage}");
    // Displays a SnackBar for error messages if not loading.
    // This is scheduled after the current frame build to avoid build-time state changes causing issues.
    if (currentUiState.errorMessage != null && !currentUiState.isLoading) { // Não mostrar erro se estiver carregando novo
      print("MAIN_SCREEN: Condition MET for SnackBar. Error: ${currentUiState.errorMessage}");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Reads the latest state within the callback to ensure it's up-to-date.
        final latestUiState = context.read<UiStateNotifier>().uiState; // Use .read aqui dentro do callback
        print("MAIN_SCREEN: addPostFrameCallback EXECUTING. Error from latestUiState: ${latestUiState.errorMessage}, context valid: ${context.mounted}");
        // Ensures the widget is still mounted and an error exists before showing SnackBar.
        if (context.mounted && latestUiState.errorMessage != null) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar(); // Remove any existing SnackBar.
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
      });
    } else {
      // Logs why SnackBar is not shown if an error message exists but is loading, or no error.
      if (currentUiState.errorMessage != null) { // Log se o erro existe mas isLoading é true
        print("MAIN_SCREEN: Condition NOT MET for SnackBar because isLoading is ${currentUiState.isLoading}. Error: ${currentUiState.errorMessage}");
      } else if (!currentUiState.isLoading){
        print("MAIN_SCREEN: Condition NOT MET for SnackBar because errorMessage is null. isLoading: ${currentUiState.isLoading}");
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentUiState.title), // AppBar title from UI state.
        actions: [
          // Refresh button to reset the UI.
          IconButton(
            icon: Icon(Icons.refresh),
            // Disables button if UI is currently loading.
            onPressed: currentUiState.isLoading ? null : () {
              context.read<UiStateNotifier>().resetUi(); // Resets UI via notifier.
              _promptController.clear(); // Clears the input field.
            },
          ),
        ],
      ),
      backgroundColor: currentUiState.backgroundColor, // Background color from UI state.
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Dynamically displays a list of components from the UI state.
            Expanded(
              child: ListView.builder(
                itemCount: currentUiState.componentProperties.length,
                itemBuilder: (context, index) {
                  final component = currentUiState.componentProperties[index];
                  // Renders text components.
                  if (component.type == 'text') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(component.text, style: TextStyle(fontSize: 18, color: component.color)),
                    );
                    // Renders button components.
                  } else if (component.type == 'button') {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton(
                        onPressed: () {}, // Button action is currently a no-op.
                        child: Text(component.text),
                        style: ElevatedButton.styleFrom(backgroundColor: component.color),
                      ),
                    );
                  }
                  return SizedBox.shrink(); // Fallback for unknown component types.
                },
              ),
            ),
            // Shows a loading indicator if the UI state is loading.
            if (currentUiState.isLoading)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Center(child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(textFieldTextColor),
                )),
              ),
            // Input area for user commands.
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _promptController,
                      style: TextStyle(color: textFieldTextColor),  // Text color adapts to background.
                      decoration: InputDecoration(
                        hintText: "Write command here...",
                        hintStyle: TextStyle(color: textFieldTextColor.withOpacity(0.7)), // Um pouco mais sutil
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: textFieldTextColor.withOpacity(0.7)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: textFieldTextColor.withOpacity(0.7)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: textFieldTextColor, width: 2.0),
                        ),
                      ),
                      enabled: !currentUiState.isLoading, // Disables input if loading.
                      onSubmitted: currentUiState.isLoading ? null : (value) {
                        _submitPrompt();  // Submits prompt on enter/done.
                      }
                    ),
                  ),
                  SizedBox(width: 8),
                  // Send button for the command.
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: textFieldTextColor,// Button background contrasts with screen background.
                      foregroundColor: currentUiState.backgroundColor,  // Button text contrasts with button background.
                    ).copyWith(),
                    // Shows a small loading indicator on the button if loading.
                    child: currentUiState.isLoading ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(currentUiState.backgroundColor))) : Text('Send'),
                    onPressed: currentUiState.isLoading ? null : _submitPrompt, // Disables if loading.
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