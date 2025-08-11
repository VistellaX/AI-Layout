# ai_layout

Dynamic layout with LLM

This is a Flutter project that demonstrates how to use a Large Language Model (LLM), specifically Google's Gemini API, to dynamically modify an application's user interface based on natural language commands.

Features:
  • Change the screen title.
  • Change the screen background color.
  • Add UI components (Text, Buttons) to the screen.
  • Update the text of existing components.
  • Remove components from the screen.
  • Clear all dynamic components.
  • Display loading feedback and error messages.
 
Prerequisites:
Before you begin, make sure you have the following installed:
  1. Flutter SDK: Flutter Installation Instructions
  2. A Code Editor: Such as VS Code with the Flutter extension, or Android Studio.
  3. Google Gemini API Key: You'll need an API key to use Gemini.
    • Go to Google AI Studio (formerly MakerSuite).
    • Create a new project or use an existing one.
    • Click "Get API key" and copy your key. Keep this key safe and never commit it to your public Git repository.

Project Setup:
  1. Clone the Repository: git clone https://github.com/YOUR_USER/YOUR_REPOSITORY.git
  cd YOUR_REPOSITORY
  2. Configure the Gemini API Key: The project expects the Gemini API key to be configured in the code.
    • In the root of the AI Layout project, create a new file named ".env".
    • Add:
    • GEMINI_API_KEY = "your API key",
    • GEMINI_API_URL = "model URL". Example: "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key = your API key again".
  3. Install Dependencies: Run the following command in the project root to fetch all Flutter dependencies: flutter pub get
  
How to Build and Run:
1. Connect a Device or Launch an Emulator/Simulator:
• For physical devices, follow Flutter's instructions to set up your device for development (Android, iOS).
• For emulators/simulators, launch one through Android Studio (AVD Manager) or Xcode (Simulators).
2. Run the App: From the project root, run flutter run. This will build the app and install it on the connected device/emulator.
   
How to Test:
After the application launches, you'll see a simple interface with a text field at the bottom.
1. Command Input Field:
  • Enter commands in natural language to modify the UI.
  • Press the "Submit" button or the "Enter" key on your keyboard to submit the command.
2. Example Commands to Test:
  • Change the title to My Awesome App
  • Change the background color to blue
  • Set the background to white
  • Add text that says Hello World
  • Create a red button with the text Click Here
  • Place 'Flutter is Cool' in the first item (assuming the first item is text)
  • Change the color of component 0 to green
  • Remove the last component
  • Delete the item at position 1
  • Clear the screen
  • Make the title 'Gemini Test' and the background orange, then add the text 'Success!' (multiple commands)

3. Observe the Changes:
  • The UI should update dynamically according to your commands.
  • A loading indicator will appear while the command is being processed by the Gemini API.
4. Reset Button:
  • The refresh icon in the app bar resets the UI to its initial state, and you can also write the command in natural language.

Project Structure (Main Files)
  • lib/main.dart: Application entry point, Provider configuration.
  • lib/screens/main_screen.dart: The main UI widget, containing the layout and prompt input field.
  • lib/services/ui_state_notifier.dart: Manages the UI state using ChangeNotifier. Contains the logic for processing Gemini commands and applying changes.
  • lib/services/ui_state.dart: Defines the UiState and ComponentProperty classes that represent the interface state.
  • lib/services/gemini_service.dart: Responsible for interacting with the Gemini API, sending the user prompt and system instruction, and receiving the JSON payload.

Common Troubleshooting:
  • API Error / "Error connecting to Gemini service":
  • Verify that your Gemini API key in gemini_service.dart is correct and valid.
  • Check your internet connection.
  • Consult the debug console for more detailed API error messages.
  • Commands Not Understood:
    • The _systemInstruction in gemini_service.dart defines how Gemini should interpret commands and what JSON actions it can generate. If the commands aren't working, you may need to refine this instruction.
    • Try being more specific or rephrasing your command.
  • Invalid JSON Issues:
  • Gemini can sometimes return extra text or format JSON incorrectly (e.g., with markdown blocks). gemini_service.dart attempts to clean this up, but _systemInstruction is the first line of defense.
 • Compilation/Flutter Issues:
• Make sure the Flutter SDK is configured correctly.
  • Run flutter doctor to diagnose common Flutter issues.
  • Try flutter clean followed by flutter pub get.
