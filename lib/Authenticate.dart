import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trying_flutter_sound/ChildSelection.dart';
import 'package:trying_flutter_sound/LoginScreen.dart';
import 'package:trying_flutter_sound/LevelSelection.dart';

class Authenticate extends StatefulWidget {
  const Authenticate({Key? key}) : super(key: key);

  @override
  State<Authenticate> createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {

  final _auth = FirebaseAuth.instance;
  @override
  Widget build(BuildContext context) {
    if (_auth.currentUser == null) {
      return LoginScreen();
    }
    return ChildSelection();
  }
}
