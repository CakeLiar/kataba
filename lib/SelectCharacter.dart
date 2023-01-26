import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:trying_flutter_sound/LevelSelection.dart';

import 'SignupScreen.dart';
class SelectCharacter extends StatefulWidget {
  final String childId;
  const SelectCharacter({Key? key, required this.childId}) : super(key: key);

  @override
  State<SelectCharacter> createState() => _SelectCharacterState();
}

class _SelectCharacterState extends State<SelectCharacter> {

  void pleaseSetState(){
    setState(() {

    });
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _name = TextEditingController();
    TextEditingController _age = TextEditingController();

    final size = MediaQuery.of(context).size;


    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 80),
            Text(
              'اختر شخصيتك',
              style: TextStyle (
                fontSize: 40,
                fontWeight: FontWeight.bold,
              )
            ),
            SizedBox(height: 40),
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => LevelSelection(childId: widget.childId),
                          ),
                        );
                      },
                      child: Container(
                        width: size.width/2.7,
                        height: size.width/2.7,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)
                          ),
                          child: Image.asset(
                              'assets/images/char6.png'
                          ),
                        )
                      ),
                    ),
                    Container(
                        width: size.width/2.7,
                        height: size.width/2.7,
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Image.asset(
                                    'assets/images/char1.png'
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  child: Image.asset(
                                      'assets/images/lock.png'
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                        width: size.width/2.7,
                        height: size.width/2.7,
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Image.asset(
                                    'assets/images/char3.png'
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  child: Image.asset(
                                      'assets/images/lock.png'
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                    ),
                    Container(
                        width: size.width/2.7,
                        height: size.width/2.7,
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Image.asset(
                                    'assets/images/char4.png'
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  child: Image.asset(
                                      'assets/images/lock.png'
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Container(
                        width: size.width/2.7,
                        height: size.width/2.7,
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Image.asset(
                                    'assets/images/char5.png'
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  child: Image.asset(
                                      'assets/images/lock.png'
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                    ),
                    Container(
                        width: size.width/2.7,
                        height: size.width/2.7,
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15)
                          ),
                          child: Stack(
                            children: [
                              Center(
                                child: Image.asset(
                                    'assets/images/char2.png'
                                ),
                              ),
                              Center(
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  child: Image.asset(
                                      'assets/images/lock.png'
                                  ),
                                ),
                              )
                            ],
                          ),
                        )
                    ),
                  ],
                ),
                
              ],
            )
          ]
        ),
      )
    );
  }
}
