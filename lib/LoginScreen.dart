import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trying_flutter_sound/AddChild.dart';
import 'package:trying_flutter_sound/Authenticate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:trying_flutter_sound/ChildSelection.dart';

import 'SignupScreen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool isLoading = false;

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
    TextEditingController _email = TextEditingController();
    TextEditingController _password = TextEditingController();

    final size = MediaQuery.of(context).size;



    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      body: Stack(
        children: [
          Image.asset('assets/images/spiral.png'),
          Center(
            child: isLoading? CircularProgressIndicator(color: Colors.white) : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(height: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: size.width/1.1,
                      child: Text(
                        'مرحبًا!',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        )
                      ),
                    ),
                    Container(
                      width: size.width/1.1,
                      child: Text(
                        'تسجيل الدخول',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        )
                      ),
                    ),

                    SizedBox(height: 50),

                    Container(
                      width: size.width/1.2,
                      child: CupertinoTextField(
                        placeholder: "البريد الالكتروني",
                        padding: EdgeInsets.only(right: 20, left: 20, top: 10, bottom: 10),
                        controller: _email,
                      ),
                    ),
                    SizedBox(height: 20),
                    Container(
                      width: size.width/1.2,
                      child: CupertinoTextField(
                        placeholder: "كلمة المرور",
                        padding: EdgeInsets.only(right: 20, left: 20, top: 10, bottom: 10),
                        controller: _password,
                        obscureText: true,

                      ),
                    ),
                    SizedBox(height:10),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => SignupScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "انشئ حساب جديد",
                        style: TextStyle(
                          color: Color(0xFF1D95C1),
                        )
                      ),
                    )
                  ]
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom:20.0),
                  child: Container(
                      height: 60,
                      width: size.width/1.2,
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        child: Container(
                            height: 50,
                            width: size.width,
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Color(0xFFDD8D5F),
                                    Color(0xFF9459A4),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(25)
                            ),
                            child: GestureDetector(
                              onTap: () async {
                                setState(() {
                                  isLoading = true;
                                });
                                if (_email.text.isEmpty) {
                                  showLoginError(context, 'خانة الأيميل فارغة');
                                  setState(() {
                                    isLoading = false;
                                  });
                                  return;
                                }

                                if (!_email.text.contains('@') || !_email.text.contains('.')) {

                                  showLoginError(context, 'خانة الأيميل مخطوءة');
                                  setState(() {
                                    isLoading = false;
                                  });
                                  return;
                                }
                                if (_password.text.length < 8) {
                                  showLoginError(context, 'كلمة السر يجب انو تكون أكثر من 8 محارف');
                                  setState(() {
                                    isLoading = false;
                                  });
                                  return;
                                }

                                if (true) {
                                  //var r = await SharedPreferences.getInstance();
                                  //await r.setString('email', '123123');
                                  FirebaseAuth _auth = FirebaseAuth.instance;
                                  _auth.signInWithEmailAndPassword(email: _email.text, password: _password.text).then((value){
                                    if(value.user!=null) {
                                      print(value.user);
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => ChildSelection(),
                                        ),
                                      );
                                      setState((){
                                        isLoading = false;
                                      });
                                    } else {
                                      setState((){
                                        isLoading = false;
                                      });
                                    }
                                  }).catchError((e){
                                    print("ERROR LOGING IN: ${e.toString()}");

                                    if (e.toString().contains('[firebase_auth/user-not-found]')) {
                                      showLoginError(context, 'البريد الاكتروني غير موجود');
                                    }
                                    if (e.toString().contains('password')) {
                                      showLoginError(context, 'كلمة السر مغلوطة');
                                    }
                                    setState((){
                                      isLoading = false;
                                    });
                                  });
                                } else {
                                  setState(() {
                                    isLoading = false;
                                  });
                                }
                              },
                              child: Center(
                                child: Text(
                                    "تسجيل دخول",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20
                                    )
                                )
                              ),
                            )//declare your widget here
                        ),
                      )
                  ),
                ),
              ],
            ),
          ),
        ],
      )
    );
  }
}
