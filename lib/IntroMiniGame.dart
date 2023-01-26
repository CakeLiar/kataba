import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trying_flutter_sound/MiniGame2.dart';
import 'LevelSelection.dart';
import 'package:soundpool/soundpool.dart';

import 'MiniGame.dart';


class IntroMiniGame extends StatefulWidget {

  final String name;
  final String childId;
  final myScore;
  IntroMiniGame({required this.name, required this.childId, required this.myScore});

  @override
  State<IntroMiniGame> createState() => _IntroMiniGameState();
}

class _IntroMiniGameState extends State<IntroMiniGame> {


  Soundpool pool = Soundpool.fromOptions(options: SoundpoolOptions());
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;

  int stringToInt(String s) {
    if (s == '1')
      return 1;
    if (s == '2')
      return 2;
    if (s == '3')
      return 3;
    if (s == '4')
      return 4;
    if (s == '5')
      return 5;
    return 1;


  }
  Widget starIcon (int indx) {
    return
      Container(
          width: 15,
          height: 15,
          child: false? Image.asset('assets/images/litstar.png') : Image.asset('assets/images/emptystar.png')
      );
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF95EDED).withOpacity(1),
              Color(0xFF6DAE62).withOpacity(.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 50),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12, left: 12),
                  child: Container(
                      width: 100,
                      height: 40,
                      child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20)
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 7.0, right: 7),
                            child: Row(
                              children: [
                                starIcon(1),
                                starIcon(2),
                                starIcon(3),
                                starIcon(4),
                                starIcon(5),
                              ],
                            ),
                          )
                      )
                  ),
                ),
                Container(
                  width: 20,
                  height: 20,
                  child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => LevelSelection(childId: widget.childId),
                          ),
                        );
                      },
                      child: Image.asset(
                          'assets/images/home.png'
                      )
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12.0, left: 12.0),
                  child: SizedBox(width: 100),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                Container (
                  width: size.width/1.8,
                  height: size.width/1.8,
                  child: Image.asset('assets/images/char6.png'),
                ),
                Container(
                  width: size.width/1.2,
                  height: size.width/1.2,
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Center(
                      child : Column(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,

                        children: [
                          SizedBox(height: 20),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'تحدٍّ جديد ينتظرنا',
                                style: TextStyle(
                                  fontSize: 20,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                  'لنواجه التحدي!',
                                  textDirection: TextDirection.rtl,
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: Colors.black,
                                  )
                              ),
                            ]
                          ),
                          Container(
                              height: 50,
                              width: 120,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                color: Color(0xFFEFBA44),
                                child: GestureDetector(
                                  onTap: () {
                                    print('should go');
                                    Navigator.of(context).pushReplacement(
                                      MaterialPageRoute(
                                          builder: (context) => MiniGame(id: 0, level: stringToInt(widget.name), corrects: [0, 0, 0, 0, 0], childId: widget.childId, myScore: widget.myScore,)
                                      ),
                                    );
                                    setState(() {

                                    });
                                  },
                                  child: Center(
                                    child: Text(
                                        "التالي",
                                        style: TextStyle(
                                          fontSize: 20,
                                          color: Colors.white,
                                        )
                                    ),
                                  ),
                                ),
                              )
                          ),
                        ],
                      ),
                    )
                  )
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
