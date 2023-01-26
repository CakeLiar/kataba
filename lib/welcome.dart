import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundpool/soundpool.dart';
import 'package:trying_flutter_sound/Authenticate.dart';
import 'package:trying_flutter_sound/ChildSelection.dart';
import 'package:trying_flutter_sound/LevelSelection.dart';

import 'LoginScreen.dart';
class welcomeScreen extends StatefulWidget {
  const welcomeScreen({Key? key}) : super(key: key);

  @override
  State<welcomeScreen> createState() => _welcomeScreenState();
}

class _welcomeScreenState extends State<welcomeScreen> {


  bool did = false;
  Soundpool pool = Soundpool.fromOptions(options: SoundpoolOptions());
  bool checked = false;
  bool logged = false;

  void playVoice(String ast) async {

    int soundId = await rootBundle.load(ast).then((ByteData soundData) {
      return pool.load(soundData);
    });
    int streamId = await pool.play(soundId);
  }

  void check () async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey("email")) {
      logged = true;
    } else {
      logged = false;
    }
    setState((){
      checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!did) {
      did = true;
      check();
      playVoice('assets/audio/appnameaudio.m4a');
    }
    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png'),
            (!checked)? CircularProgressIndicator(color: Colors.black) : GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => Authenticate()
                  ),
                );
              },
              
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)
                ),
                child: Container(
                  height: 50,
                  width: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFDD8D5F),
                        Color(0xFF9459A4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20)
                  ),
                  child: Center(
                    child: Text(
                      "ابدأ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20
                      )
                    )
                  ), //declare your widget here
                ),
              ),
            ),
          ]
        ),
      )
    );
  }
}
