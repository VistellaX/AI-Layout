import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_layout/screens/main_screen.dart';
import 'package:ai_layout/services/ui_state_notifier.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(
      ChangeNotifierProvider(
        create: (context) {
          print("PROVIDER: Creating UiStateNotifier instance.");
          final notifier = UiStateNotifier();
          print("PROVIDER: UiStateNotifier INSTANCE CREATED with hashCode: ${notifier.hashCode}");
          return notifier;
        },
        child: MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dynamic Layout',
      home: MainScreen(),
    );
  }
}
