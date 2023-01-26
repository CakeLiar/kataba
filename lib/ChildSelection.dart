import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trying_flutter_sound/AddChild.dart';
import 'package:trying_flutter_sound/LevelSelection.dart';

import 'SelectCharacter.dart';

class ChildSelection extends StatefulWidget {
  const ChildSelection({Key? key}) : super(key: key);

  @override
  State<ChildSelection> createState() => _ChildSelectionState();
}



class _ChildSelectionState extends State<ChildSelection> {

  List<Map<String, dynamic>> children  = [];

  void orderSetState() {
    setState(() {

    });
  }


  void doCheck() async {
    final _firestore = FirebaseFirestore.instance;
    final _auth = FirebaseAuth.instance;

    print("checking");
    List<Map<String, dynamic>> childs = [];
    await _firestore.collection('users').doc(_auth.currentUser?.uid).collection('children').get().then((value){
      value.docs.forEach( (doc) {
        Map<String, dynamic> curr = doc.data();

        if (curr['score'] != null && curr['name'] != null && curr['age'] != null)
          childs.add({'score' : curr['score'].toString(), 'name' : curr['name'], 'age': curr['age']});
      });
    });
    print(childs);
    setState((){
      children = childs;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    doCheck();
  }


  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(height: 20),
          Column(
            children: [

              SizedBox(height:95),

              Center(
                child: Text(
                  "اختر طفل",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 35,
                  )
                ),
              ),

              Container(
                width: size.width/1.5,
                height: size.height/1.5,
                child: ListView.builder(
                  shrinkWrap : true,
                  physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  padding: EdgeInsets.only(top:0),
                  itemCount: children.length,
                  scrollDirection: Axis.vertical,
                  itemBuilder: (BuildContext context, int index) {
                    return Container(
                      width: size.width/1.5,
                      height: size.width/1.5,
                      child: Card(
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                children[index]['name'],
                                style: TextStyle (
                                  fontSize: 22,
                                  color : Color(0xFFDD8D5F)
                                )
                              ),
                              Card(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  color: Colors.white,
                                  shadowColor: Colors.transparent,
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10.0, bottom: 10.0, right: 0, left: 0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset('assets/images/trophy.png'),
                                        Text(children[index]['score'])
                                      ],
                                    ),
                                  )
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (context) => SelectCharacter(childId: '${children[index]['name']}+${children[index]['age']}'),
                                    ),
                                  );
                                },
                                child: Card(
                                  color: Color(0xFF9459A4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 10.0, bottom: 10, left: 20, right: 20),
                                    child: Text(
                                      'اختر',
                                      style : TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.w700
                                      )
                                    ),
                                  ),
                                ),
                              )
                            ],
                          )
                        )
                      )
                    );
                  }
                ),
              ),

              SizedBox(height: 10),

            ],
          ),
          Container(
            width: size.width/1.2,
            height: 80,
            child: Column(
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Container(
                      height: 60,
                      width: size.width,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(0xFFDD8D5F),
                            Color(0xFF9459A4)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => AddChild(),
                            ),
                          );
                        },
                        child: Center(
                          child: Text(
                              "أضف طفل",
                              style: TextStyle(
                                fontSize: 30,
                                color: Colors.white,
                              )
                          ),
                        ),
                      )//declare your widget here
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
