import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trying_flutter_sound/AddChild.dart';
import 'package:trying_flutter_sound/LoginScreen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {

  bool isLoading = false;
  bool showPassword = false;

  TextEditingController _name = TextEditingController();
  TextEditingController _email = TextEditingController();
  TextEditingController _password = TextEditingController();

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
      body: Stack(
        children: [
          Image.asset('assets/images/spiral.png'),
          Center(
            child: isLoading? CircularProgressIndicator(color: Colors.white) :  Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(height:size.height/20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: size.width/1.1,
                      child: Text(
                        'إنشاء حساب جديد',
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
                        placeholder: "الاسم",
                        padding: EdgeInsets.only(right: 20, left: 20, top: 10, bottom: 10),
                        controller: _name,

                      ),
                    ),
                    SizedBox(height: 20),

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
                        obscureText: !showPassword,
                        suffix: Container(
                          width: 30,
                          height: 30,
                          child: GestureDetector(
                            onTap: () {
                              setState((){
                                showPassword = !showPassword;
                              });
                            },
                            child: Icon(showPassword? CupertinoIcons.eye_slash_fill : CupertinoIcons.eye_fill, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 10),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => LoginScreen(),
                          ),
                        );
                      },
                      child: Text(
                        "سجل الدخول",
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

                                if (_name.text.isEmpty) {
                                  showLoginError(context, 'الرجاء ادخال الاسم');
                                  setState(() {
                                    isLoading = false;
                                  });
                                  return;
                                }

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
                                  FirebaseAuth _auth = FirebaseAuth.instance;
                                  _auth.createUserWithEmailAndPassword(email: _email.text, password: _password.text).then((value){
                                    if(value != null) {
                                      Navigator.of(context).pushReplacement(
                                        MaterialPageRoute(
                                          builder: (context) => AddChild(),
                                        ),
                                      );
                                    } else {
                                      setState(() {
                                        isLoading = false;
                                      });
                                    }
                                  }).catchError((e){
                                    print('error: ${e.toString()}');
                                    if (e.toString().contains('email-already-in-use')){
                                      showLoginError(context, 'البريد الاكتروني مستخدم سابقا');
                                    }
                                    setState(() {
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
                                      "تسجيل جديد",
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
