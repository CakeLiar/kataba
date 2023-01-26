import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trying_flutter_sound/IntroMiniGame.dart';
import 'package:trying_flutter_sound/IntroMiniGameVoiceOrbs.dart';
import 'package:trying_flutter_sound/MiniGameVoiceOrbs.dart';
import 'package:trying_flutter_sound/pleasework.dart';

import 'MiniGame2.dart';
import 'MiniGameVoiceOrbs.dart';
import 'StoreScreen.dart';

class LevelSelection extends StatefulWidget {
  final String childId;
  const LevelSelection({Key? key, required  this.childId}) : super(key: key);

  @override
  State<LevelSelection> createState() => _LevelSelectionState();
}

class _LevelSelectionState extends State<LevelSelection> {
  int score = 0;
  final _keys = [GlobalKey(), GlobalKey(), GlobalKey(), GlobalKey(), GlobalKey()];

  List<double> xs = [-1, -1, -1, -1, -1], ys = [-1, -1, -1, -1, -1];

  void _getPosition(int i) {

    RenderBox? box = _keys[i].currentContext!.findRenderObject() as RenderBox?;
    print('entering$box');

    Offset position = box!.localToGlobal(Offset.zero);
    print('entering 2$position');

    setState(() {
      xs[i] = position.dx;
      ys[i] = position.dy;
    });
  }

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

  void getScore ()async {

    final _firestore = FirebaseFirestore.instance;
    final _auth = FirebaseAuth.instance;


    String score_ = '0';
    await _firestore.collection('users').doc(_auth.currentUser?.uid).collection('children').doc(widget.childId).get().then((value){
      Map<String, dynamic>mp = value.data() as Map<String, dynamic>;
      score_ = mp['score'].toString();
    });
    setState((){
      score = double.parse(score_).round();
    });


  }
  @override
  void initState() {
    print('initstate');
    Future.delayed(Duration.zero, () => myFakeWidget());
    getScore();
    super.initState();
  }



  @override
  Widget build(BuildContext context) {
    getScore();
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: SingleChildScrollView(
        child: Container(
          width: size.width,
          child: Stack(
            children: [
              CustomPaint(
                size: Size(size.width , size.height),
                painter: Line(xs[0], xs[1], ys[0], ys[1]),
              ),
              CustomPaint(
                size: Size(size.width , size.height),
                painter: Line(xs[1], xs[2], ys[1], ys[2]),
              ),
              CustomPaint(
                size: Size(size.width , size.height),
                painter: Line(xs[2], xs[3], ys[2], ys[3]),
              ),
              CustomPaint(
                size: Size(size.width , size.height),
                painter: Line(xs[3], xs[4], ys[3], ys[4]),
              ),
              Column(
                children: [
                  SizedBox(height:50),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => StoreScreen(childId: widget.childId),
                            ),
                          );
                        },
                        child: Icon(
                          CupertinoIcons.cart_fill
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Row(
                        children: [
                          Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)
                            ),
                            child: Padding(
                              padding: EdgeInsets.only(top: 5, bottom: 5, right: 10, left: 10),
                              child: Text(
                                score.toString(),
                                style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.black
                                )
                            ),
                            )
                          ),
                          Container(
                            width: 40,
                            height: 40,
                            child: Image.asset('assets/images/trophy.png')
                          )
                        ],
                      ),
                    ]
                  ),


                  Container(
                    height: size.height/1.1+50,
                    child: Stack(
                      children: [
                        Positioned(
                          bottom: 50,
                          child: levelCircle(size, '5', true, (score>10000), Color(0xFF0965C0), 4)
                        ),

                        Positioned(
                          bottom: 150,
                          child: levelCircle(size, '4', false, (score>10000), Color(0xFFDD83AD), 3)
                        ),

                        Positioned(
                          bottom: 250,
                          child: levelCircle(size, '3', true, (score>10000), Color(0xFF8752A3), 2)
                        ),

                        Positioned(
                          bottom: 350,
                          child: levelCircle(size, '2', false, (score>=1000), Color(0xFF2BB2E4), 1)
                        ),
                        Positioned(
                          bottom: 450,
                          child: levelCircle(size, '1', true, (score>=0), Color(0xFFEA5753), 0)
                        ),
                      ],
                    )
                  )
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget myFakeWidget() {
    if (_keys[0] == null) {
      print("NULL!!!");
    } else if (xs[0] == -1) {
      print('got xs');
      _getPosition(0);
      _getPosition(1);
      _getPosition(2);
      _getPosition(3);
      _getPosition(4);
      print ('${xs[2]} ${ys[2]}');
    }
    return Container(
    );
  }

  Widget levelCircle(Size size, String name, bool right, bool _activated, Color clr, int index) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        (!right)? Container () : SizedBox(
          width: size.width/2,
        ),
        Padding(
          padding: EdgeInsets.only(right: 35, left: 35),
          child: Container(
            key: _keys[index],
            width: size.width/3.3,
            height: size.width/3.3+(((size.width/3.4)/1.2)*1.7),
            child: Stack(
              children: [
                Center(
                  child: GestureDetector(
                    onTap: (){
                      if (name == '1') {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => IntroMiniGameVoiceOrbs(name: '1', childId: widget.childId, myScore: score)
                          ),
                        );
                      } else if (name == '2' && score >= 1000) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (context) => IntroMiniGame(name: '2', childId: widget.childId, myScore: score)
                          ),
                        );
                      } else {
                        return;
                      }
                    },
                    child: Container(
                      height: size.width/3.3,
                      child: Card (
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(360.0),
                        ),
                        color: Color(0xFFFFD066),
                        child: Stack(
                          children: [
                            Center(
                              child: true? Container(
                                width: size.width/5,
                                height: size.width/5,
                                child: Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(360),
                                  ),
                                  color: clr,
                                )
                              ) : Text(
                                "$name"
                              ) ,
                            ),
                            _activated? Center(
                              child: Container(
                                child: Icon(CupertinoIcons.lock_open_fill, color: Colors.white)
                              ),
                            ) : Center(
                              child: Container (
                                child : Icon(CupertinoIcons.lock_fill, color: Colors.white)
                              ),
                            ),
                          ]
                        )
                      ),
                    ),
                  ),
                ),
                !(name == '1' && score >= 0 && score < 1000)? Container() : Positioned(
                  bottom: 160,
                  child: Container(
                    width: size.width/3.4, height: (size.width/3.4)/1.2,
                    child: Image.asset(
                        'assets/images/char6.png',
                      fit: BoxFit.fitHeight
                    ),
                  ),
                ),
                !(name == '2' && score >= 1000)? Container() : Positioned(
                  bottom: 160,
                  child: Container(
                    width: size.width/3.4, height: (size.width/3.4)/1.2,
                    child: Image.asset(
                        'assets/images/char6.png'
                    ),
                  ),
                ),

              ],
            )
          ),
        ),

        (right)? Container() : SizedBox(
          width: size.width/2,
        ),
      ]
    );
  }
}

class Line extends CustomPainter {
  final double x1, x2, y1, y2;

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    paint.color = Color(0xFFFFD066);
    paint.strokeWidth = 20;
    paint.strokeCap = StrokeCap.round;

    Offset startingOffset = Offset(x1+(size.width/3.3+50)/2, y1+(size.width/3.3+120)/2);
    Offset endingOffset = Offset(x2+(size.width/3.3+50)/2, y2+(size.width/3.3+120)/2);

    canvas.drawLine(startingOffset, endingOffset, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }

  Line(this.x1, this.x2, this.y1, this.y2);
}