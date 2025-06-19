import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_phoenix/flutter_phoenix.dart';
import 'screens/welcome_screen.dart';

void main() {
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      child: Container(
        padding: const EdgeInsets.all(20),
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text('Coś poszło nie tak', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 16),
              Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () => Phoenix.rebirth(context),
                  child: const Text('Restartuj aplikację'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  };
  runApp(Phoenix(child: const AIWrozkaApp()));
}

class AIWrozkaApp extends StatelessWidget {
  const AIWrozkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ustawienia systemowe
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    return MaterialApp(
      title: 'AI Wróżka',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        textTheme: GoogleFonts.cinzelDecorativeTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      home: const WelcomeScreen(),
    );
  }
}
