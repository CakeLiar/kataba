import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import 'package:trying_flutter_sound/AddChild.dart';
import 'package:trying_flutter_sound/LevelSelection.dart';
import 'package:trying_flutter_sound/LoginScreen.dart';
import 'package:trying_flutter_sound/MiniGameVoiceOrbs.dart';
import 'package:trying_flutter_sound/SoundRecorder.dart';
import 'package:trying_flutter_sound/pleasework.dart';
import 'package:trying_flutter_sound/welcome.dart';
import 'package:google_fonts/google_fonts.dart';
import 'SignupScreen.dart';
import 'firebase_options.dart';

import 'Authenticate.dart';
import 'GreatJob.dart';
import 'MiniGame2.dart';


Future main() async {
  WidgetsFlutterBinding.ensureInitialized();
  DateTime dt1 = DateTime.parse("2023-02-02 00:00:00");
  print(DateTime.now());

  if (DateTime.now().compareTo(dt1) > 0) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Text(
        "ERROR CODE 681"
      )
    );
  }

  print('hello');

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('booted');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Tajawal'
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  @override
  Widget build(BuildContext context) {
    print("Began");
    return MaterialApp(
      theme: ThemeData(
        textTheme: GoogleFonts.almaraiTextTheme(),
        primarySwatch: Colors.grey,
        scaffoldBackgroundColor: Color(0xFFFFFAF0),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 25,
            fontWeight: FontWeight.bold,
          ),
          foregroundColor: Colors.black,
          backgroundColor: Color(0xFFEEEEEE),
          shadowColor: Colors.transparent,
          systemOverlayStyle: SystemUiOverlayStyle(
            // Status bar color
            statusBarColor: Colors.transparent,

            // Status bar brightness (optional)
            statusBarIconBrightness: Brightness.dark, // For Android (dark icons)
            statusBarBrightness: Brightness.light, // For iOS (dark icons)
          ),
        )
      ),
      debugShowCheckedModeBanner: false,
      home: welcomeScreen()
    );
  }
}
