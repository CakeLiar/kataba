import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trying_flutter_sound/SelectCharacter.dart';
import 'ChildSelection.dart';

import 'SignupScreen.dart';
class AddChild extends StatefulWidget {
  const AddChild({Key? key}) : super(key: key);

  @override
  State<AddChild> createState() => _AddChildState();
}

class _AddChildState extends State<AddChild> {


  TextEditingController _name = TextEditingController();
  TextEditingController _age = TextEditingController();
  bool isLoading = false;

  String sex = 'male';
  String relationship = 'ام';

  void showLoginError (BuildContext context, String error) {
    showCupertinoDialog(
        context: context,
        builder: (context) {
          return CupertinoAlertDialog(
            title: Text('خطأ'),
            content: Text(error),
            actions: <Widget>[
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('تابع', style: TextStyle(color: Color(0xFF9459A4))))
            ],
          );
        });
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            SizedBox(height: 80),
            Text(
              'اضافة طفل',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
              )
            ),
            SizedBox(height: 80),
            Container(
              width: size.width/1.2,
              child: CupertinoTextField(
                placeholder: "اسم الطفل",
                padding: EdgeInsets.only(right: 20, left: 20, top: 10, bottom: 10),
                controller: _name,
              ),
            ),
            SizedBox(height: 20),
            Container(
              width: size.width/1.2,
              child: CupertinoTextField(
                placeholder: "العمر",
                padding: EdgeInsets.only(right: 20, left: 20, top: 10, bottom: 10),
                controller: _age,
                keyboardType: TextInputType.number,
              ),
            ),
            SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () {

                    setState((){
                      sex = 'male';
                    });

                    print("TAPPED MALE $sex");
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    color: Color(sex=='male'? 0xFFDD8D5F: 0xFFFFFFFF),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 35, left: 35, top: 15, bottom: 15),
                      child: Text(
                        "ذكر"
                      ),
                    )
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState((){
                      sex = 'female';
                    });

                    print("TAPPED FEMALE $sex");
                  },
                  child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      color: Color(sex=='female'? 0xFFDD8D5F: 0xFFFFFFFF),
                      child: Padding(
                        padding: const EdgeInsets.only(right: 35, left: 35, top: 15, bottom: 15),
                        child: Text(
                            "انثى"
                        ),
                      )
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            Text(
              'العلاقة'
            ),
            SizedBox(height: 5),
            Container(
              width: size.width/1.4,
              height: 60,
              child: true? Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Row(
                        children: [
                          SizedBox(width:40),
                          Text(
                            relationship
                          ),
                          Container(
                            width: 40,
                            child: Icon(
                                CupertinoIcons.chevron_down
                            ),
                          )
                        ],
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      )
                    ),
                    Container(
                      width: size.width,
                      child: DropdownButton (
                        underline: Container(),
                        icon: Container(),
                        items: <String>['ام', 'اب', 'معلم', 'أخرى']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem(
                            value: value,
                            child: Text(
                              value,
                              textDirection: TextDirection.rtl,
                              textAlign: TextAlign.right,
                              style: TextStyle(fontSize: 20),
                            ),
                          );
                        }).toList(),
                        borderRadius: BorderRadius.circular(10),
                        onChanged: (Object? value) {
                          print("HELLO: $value");
                          setState(() {
                            relationship = value.toString();
                          });
                        },

                        ),
                    ),
                  ],
                ),
              ) : Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)
                ),
                child: CupertinoPicker(
                  backgroundColor: Colors.transparent,
                  itemExtent: 50,
                  onSelectedItemChanged: (_){

                  },
                  children: [
                    Center(child: Text('ام')),
                    Center(child: Text('اب')),
                    Center(child: Text('معلم')),
                    Center(child: Text('أخرى')),
                  ]
                ),
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () async {
                if (isLoading) {
                  return;
                }
                FirebaseFirestore _firestore = FirebaseFirestore.instance;
                FirebaseAuth _auth = FirebaseAuth.instance;

                setState(() {
                  isLoading = true;
                });

                if (_name.text.isEmpty) {
                  showLoginError(context, 'الرجاء ادخال الاسم');
                  setState(() {
                    isLoading = false;
                  });
                  return;
                }

                if (_age.text.isEmpty) {
                  showLoginError(context, 'الرجاء ادخال العمر');
                  setState(() {
                    isLoading = false;
                  });
                  return;
                }

                await _firestore.collection('users').doc(_auth.currentUser?.uid).collection('children').doc('${_name.text}+${_age.text}').set({
                  'score' : 0,
                  'name': _name.text,
                  'age': _age.text,
                  'sex': sex,
                  'relationship': relationship,
                }, SetOptions(merge: true)).then((v){
                  print('worked?');
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => ChildSelection(),
                    ),
                  );
                  setState(() {
                    isLoading = false;
                  });
                }).catchError((e){
                  print("ERROR $e");

                  showLoginError(context, 'الرجاء التأكد من وجود الشبكة');

                  setState(() {
                    isLoading = false;
                  });
                });


              },
              child: Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Container(
                  height: 50,
                  width: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Color(0xFFDD8D5F),
                        Color(0xFF9459A4),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Center(
                    child: isLoading? CircularProgressIndicator(color: Colors.white) : Text(
                      "حفظ",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20
                      )
                    )
                  ), //declare your widget here
                ),
              )
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => ChildSelection(),
                  ),
                );
              },
              child: Text(
                "تخطي",
                style: TextStyle(
                  fontSize: 15,
                  color: Color(0xFF9459A4),
                )
              )
            )
          ]
        ),
      )
    );
  }
}
