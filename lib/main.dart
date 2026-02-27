import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/roast_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 设置全屏、横屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  
  // 隐藏状态栏
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.immersiveSticky,
  );
  
  runApp(const CoffeeRoasterApp());
}

class CoffeeRoasterApp extends StatelessWidget {
  const CoffeeRoasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Coffee Roaster Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(
          primary: Colors.orange,
          secondary: Colors.green,
          surface: Color(0xFF2D2D2D),
          background: Color(0xFF1A1A1A),
          onBackground: Colors.white,
        ),
        scaffoldBackgroundColor: const Color(0xFF1A1A1A),
        cardTheme: CardTheme(
          color: const Color(0xFF2D2D2D),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Colors.white,
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Colors.white70,
          ),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: Colors.orange,
          inactiveTrackColor: Colors.grey[800],
          thumbColor: Colors.orange,
          overlayColor: Colors.orange.withOpacity(0.2),
          trackHeight: 4,
          thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 8,
          ),
        ),
      ),
      home: const RoastScreen(),
    );
  }
}