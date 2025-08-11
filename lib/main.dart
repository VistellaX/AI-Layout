import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ai_layout/screens/main_screen.dart';
import 'package:ai_layout/services/ui_state_notifier.dart';

void main() {
  runApp(
      ChangeNotifierProvider(
        create: (context) => UiStateNotifier(),
        child: MyApp(),
      )
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Dynamic UI',
      home: MainScreen(),
    );
  }
}
