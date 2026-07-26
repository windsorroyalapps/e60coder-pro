import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/obd_service.dart';
import 'services/channel_recorder.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChannelRecorder()),
        ChangeNotifierProvider(create: (_) => OBDService()),
      ],
      child: const E60CoderProApp(),
    ),
  );
}

class E60CoderProApp extends StatelessWidget {
  const E60CoderProApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E60Coder Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF00E5FF),
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: const ColorScheme.dark(primary: Color(0xFF00E5FF), secondary: Color(0xFFFF6D00), surface: Color(0xFF121212)),
        textTheme: GoogleFonts.orbitronTextTheme(ThemeData.dark().textTheme),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF0A0A0A), elevation: 0, centerTitle: true),
      ),
      home: const HomeScreen(),
    );
  }
}
