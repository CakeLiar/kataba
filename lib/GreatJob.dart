import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'LevelSelection.dart';
import 'package:soundpool/soundpool.dart';


class GreatJob extends StatefulWidget {

  List<double> corrects;
  String childId;
  int previousId;
  final myScore;

  GreatJob({required this.corrects, required this.childId, required this.previousId, required this.myScore});

  @override
  State<GreatJob> createState() => _GreatJobState();
}

class _GreatJobState extends State<GreatJob> {



  Soundpool pool = Soundpool.fromOptions(options: SoundpoolOptions());
  FirebaseFirestore _firestore = FirebaseFirestore.instance;
  FirebaseAuth _auth = FirebaseAuth.instance;
  bool isLoading = false;
  int correctss = 0;

  void playSuccess() async {
    int soundId = await rootBundle.load('assets/audio/congrats.wav').then((ByteData soundData) {
      return pool.load(soundData);
    });
    int streamId = await pool.play(soundId);
  }

  void updateScores () async {
    print('hellow');
    setState((){
      isLoading = true;
    });
    int score1 = 0;
    await _firestore.collection('users').doc(_auth.currentUser?.uid).collection('children').doc(widget.childId).get().then((value) {
      print('entered');
      Map<String, dynamic> mp = value.data() as Map<String, dynamic>;
      if (mp['score'].runtimeType == double)
        score1 = mp['score'].round();
      else if (mp['score'].runtimeType == String)
        score1 = double.parse(mp['score']).round();
      else if (mp['score'].runtimeType == int)
        score1 = mp['score'];
      else print("error?? mp['score'] has ${mp['score'].runtimeType} type");
    }).catchError((e){
      print('ERRORR: $e');
    });
    print("WHAT YOU GOT");
    print(score1);

    int r = (widget.myScore).round();
    int scorr = (score1 + (correctss * 1000)).round() + r;
    await _firestore.collection('users').doc(_auth.currentUser?.uid).collection('children').doc(widget.childId).set({
      'score' : scorr
    }, SetOptions(merge: true));
    setState((){
      isLoading = false;
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    playSuccess();
    print('entering firestore');
    updateScores();
    for (int i =0 ; i < widget.corrects.length; i++) {
      correctss += widget.corrects[i]==1?1:0;
    }
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
              Color(widget.previousId == 1? 0xFFFFD066 : 0xFF95EDED).withOpacity(1),
              Color(widget.previousId == 1? 0xFFEB84A0 : 0xFF6DAE62).withOpacity(.6),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SizedBox(height: 10),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 50),
                true? Container() : Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: 65,
                    height: 65,
                    child: Center(
                      child: Text(
                        (correctss).toString(),
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                        )
                      )
                    )
                  )
                ),
                Container(
                  width: size.width/1.2,
                  height: size.width/1.2,
                  child: Image.asset(
                    'assets/images/congrats.png'
                  )
                ),
                SizedBox(height: 20),
                Text(
                  'جهدٌ مُبهر!',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontSize: 30,
                    color: Colors.black,
                  )
                ),

              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom:20.0),
              child: Container(
                  height: 70,
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
                                Color(widget.previousId == 1? 0xFF9459A4 : 0xFF95EDED).withOpacity(.6),
                                Color(widget.previousId == 1? 0xFFEB84A0 : 0xFF4FB2BD).withOpacity(.8)
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(25)
                        ),
                        child: GestureDetector(
                          onTap: () {
                            if (isLoading) {
                              return;
                            }
                            print('should go');
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LevelSelection(childId: widget.childId)));
                            });
                            setState(() {

                            });
                          },
                          child: Center(
                            child: isLoading? CircularProgressIndicator(color:Colors.white) : Text(
                                "التالي",
                                style: TextStyle(
                                  fontSize: 30,
                                  color: Colors.white,
                                )
                            ),
                          ),
                        )//declare your widget here
                    ),
                  )
              ),
            ),
          ],
        ),
      ),
    );
  }
}
