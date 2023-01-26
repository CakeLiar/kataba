import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'dart:async';
import 'dart:io';
import 'package:http/http.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'GreatJob.dart';
import 'LevelSelection.dart';

class MiniGame2 extends StatefulWidget {

  final int id;
  final List<double> corrects;
  final int level;
  final String childId;
  final myScore;


  final List<String> pathToImage = ['assets/images/tamr.png', 'assets/images/bnt.png', 'assets/images/habl.png', 'assets/images/klb.png', 'assets/images/lahm.png'];
  final List<String> pathToAudio = ['assets/audio/tamr.m4a', 'assets/audio/bnt.m4a', 'assets/audio/habl.m4a', 'assets/audio/klb.m4a', 'assets/audio/lahm.m4a'];
  final List<String> correctWord = ['تمر', 'بنت', 'حبل', 'كلب', 'لحم'];

  MiniGame2({required this.id, required this.level, required this.corrects, required this.childId, required this.myScore});

  @override
  State<MiniGame2> createState() => _MiniGame2State();
}

const theSource = AudioSource.microphone;


class _MiniGame2State extends State<MiniGame2> {

  List<bool> buttonActivated = [true, true, true];
  List<String> textOfButton = ['', '', ''];
  List<bool> orbActivated =  [true, true, true];
  bool everWrong = false;
  List<int> index = [0, 1, 2];

  Stopwatch sw = Stopwatch();


  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();

  Soundpool pool = Soundpool.fromOptions(options: SoundpoolOptions());

  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mplaybackReady = false;
  String? s2tToken = null;



  Codec _codec = Codec.aacMP4;
  String? _mPath = /*'tau_file.mp4'*/null;

  bool isRecording = false;
  bool isLoading = false;

  bool correct = false;

  bool canPlay = false;

  bool checkingDuration = false;

  bool didFirstRecord = false;

  void showUnableError () {

    setState(() {
      didFirstRecord = true;
    });
    playVoice('assets/audio/admj.m4a');

    print("hello");
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('لفد تم تخطي الوقت المسموح!', textDirection: TextDirection.rtl, style: TextStyle(fontWeight: FontWeight.w700)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.0),
            ),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(
                    'يمكنك استعمال قراءة الصوت فقط 3 دقائق يوميا'
                  )
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text('تخطي',
                    textDirection: TextDirection.rtl,
                    style: TextStyle (
                      color: Color(0xFF9459A4),
                    )
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        }
    );
  }


  void checkDuration () async {
    setState(() {
      checkingDuration = true;
    });

    var _firestore = FirebaseFirestore.instance;
    var _auth = FirebaseAuth.instance;

    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('children').doc(widget.childId).get().then((value){
      Map<String, dynamic> mp = value.data() as Map<String, dynamic>;
      if (mp['voiceDuration'] > 3*60 && mp['voiceDuration'] != null) {
        showUnableError();
        print('can\'t because cloud time is more than 10');
        print(mp['voiceDuration']);
      } else {
        print("Can");
        setState(() {
          canPlay = true;
        });
      }
    }).catchError((e){
      print("ERROR: $e");
      //showUnableError();
    });

    setState((){
      checkingDuration = false;
    });
  }

  void updateDuration (currDur) async {
    var _firestore = FirebaseFirestore.instance;
    var _auth = FirebaseAuth.instance;

    int? _dur = 0;
    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('children').doc(widget.childId).get().then((value){
      Map<String, dynamic> mp = value.data() as Map<String, dynamic>;
      _dur = mp['voiceDuration'];
      if (_dur == null) {
        _dur = 0;
      }
      print('could duration: $_dur');
    }).catchError((e){
      print("ERROR: $e");
    });


    print('r:');
    int rr = (_dur! + currDur).round();
    print(rr);

    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('children').doc(widget.childId).set({
      'voiceDuration' : rr    }).then((v){
      print('saved duration');
      print(_dur! + currDur);
    }).catchError((e) {
      print("couldn't save");
    });
  }


  Future<Response> login() {
    return true?
    post(
      Uri.parse("https://px.kateb.ai:4040/api/login?email=kataba.app@gmail.com&apiKey=32a3fef636984b3a8cc7a5a7796c1e08"),
      headers: {
        'Content-Type': 'application/json'
      },
    )
        :
    post(
      Uri.https('https://px.kateb.ai:4040/api/login'),
      headers: {
        'Content-Type': 'application/json'
      },
      body: jsonEncode(''),
    );
  }

  int? stringDistance(String s1, String s2) {
    if (s1.length != s2.length)
      {
        if ((s1.contains(s2) || s2.contains(s1))) {
          return (s1.length>s2.length?s1.length-s2.length:s2.length-s1.length);
        }
      }
    int dist = 0;
    for (var i = 0; i < s1.length; i++) {
      if (s1[i]!=s2[i]) {
        dist++;
      }
    }
    return dist;
  }

  void processResult (String res) {
    Map<String, dynamic> mp = json.decode(res);
    print(mp);

    final List<dynamic> finalWords = mp['Text_String'];

    print(finalWords);

    print(finalWords.runtimeType);

    print(finalWords[0]['text']);

    print ("About to print results");
    bool did = false;
    for (var i in finalWords) {
      if (i['text'].toString().contains(widget.correctWord[widget.id]) || widget.correctWord[widget.id].contains(i['text'].toString())) {
        print('Correct!');
        playDing();
        setState((){
          didFirstRecord = true;
        });
        did = true;
      } else {
        if (i['text'].toString().length == widget.correctWord[widget.id].length) {
          if (stringDistance(i['text'].toString(), widget.correctWord[widget.id])! <= 1) {
            print('Correct!');
            playDing();
            setState((){
              didFirstRecord = true;
            });
            did = true;
          }
        }
      }
    }
    if (!did) {
      print("Empty voice");
      playVoice('asset/audio/karer.m4a');
    }
  }

  void sendRecord(File file, String pathh) async {
    print("${await file.length()}, 123123");
    print(await file.readAsBytesSync());

    isLoading = true;

    var url = Uri.parse('https://px.kateb.ai:4040/api/recognize-file');
    var req = MultipartRequest('POST', url)
      ..files.add(await MultipartFile.fromPath(
          'File', pathh))
      ..fields['LanguageCode'] = 'SA';
    print('hi2');
    req.headers['authorization'] = 'Bearer $s2tToken';
    req.headers['content-type'] = 'multipart/form-data';
    var res = await req.send();
    print("hellowing");
    if (res.statusCode != 200) {
      setState((){isLoading = false;});
      throw Exception('http.post error: statusCode= ${res.statusCode}');
    }
    final finalResponse = await res.stream.bytesToString();

    print(finalResponse);


    print("hiii");
    setState((){
      isLoading = false;
    });

    processResult(finalResponse);

  }

  void initPath () async {
    final loc = await getApplicationDocumentsDirectory();
    _mPath = loc.path+'/tau_file.mp4';
  }

  @override
  void initState() {
    doCheck();
    checkDuration();
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });

    index.shuffle();

    initPath();

    print('connecting');
    login().then((value) {
      print('hi');
      var token = ((json.decode(value.body)) as Map<String, dynamic>)['message'];
      var status = ((json.decode(value.body)) as Map<String, dynamic>)['status'];

      if (status=='OK') {
        print('Connected to S2T server');
        s2tToken = token;
      } else {
        print("BAD REQUEST");
      }
    }).catchError((e){
      print('error');
      print(e);
    });

    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
    });
    playVoice(widget.pathToAudio[widget.id]!);
    super.initState();
  }

  @override
  void dispose() {
    _mPlayer!.closePlayer();
    _mPlayer = null;

    _mRecorder!.closeRecorder();
    _mRecorder = null;
    super.dispose();
  }

  Future<void> openTheRecorder() async {
    if (!kIsWeb) {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException('Microphone permission not granted');
      }
    }
    await _mRecorder!.openRecorder();
    if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
      _codec = Codec.opusWebM;
      _mPath = 'tau_file.webm';
      if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
        _mRecorderIsInited = true;
        return;
      }
    }
    final session = await AudioSession.instance;
    await session.configure(AudioSessionConfiguration(
      avAudioSessionCategory: AVAudioSessionCategory.playAndRecord,
      avAudioSessionCategoryOptions:
      AVAudioSessionCategoryOptions.allowBluetooth |
      AVAudioSessionCategoryOptions.defaultToSpeaker,
      avAudioSessionMode: AVAudioSessionMode.spokenAudio,
      avAudioSessionRouteSharingPolicy:
      AVAudioSessionRouteSharingPolicy.defaultPolicy,
      avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
      androidAudioAttributes: const AndroidAudioAttributes(
        contentType: AndroidAudioContentType.speech,
        flags: AndroidAudioFlags.none,
        usage: AndroidAudioUsage.voiceCommunication,
      ),
      androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
      androidWillPauseWhenDucked: true,
    ));

    _mRecorderIsInited = true;
  }

  // ----------------------  Here is the code for recording and playback -------

  void record() {
    _mRecorder!
        .startRecorder(
      toFile: _mPath,
      codec: _codec,
      audioSource: theSource,
    )
        .then((value) {
      setState(() {
        isRecording = true;
        print("Started Recording $isRecording");
      });
    });
  }

  void playDing() async {

    print("shouldPlayDing");
    int soundId = await rootBundle.load('assets/audio/ding.wav').then((ByteData soundData) {
      return pool.load(soundData);
    });
    int streamId = await pool.play(soundId);
  }

  void stopRecorder() async {
    await _mRecorder!.stopRecorder().then((value) {
      setState(() {
        //var url = value;
        _mplaybackReady = true;
        isRecording = false;
        print("Stopped Recording: $isRecording");
      });
    });
    play();
  }

  Future<void> play() async {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    _mPlayer!
        .startPlayer(
        fromURI: _mPath,
        //codec: kIsWeb ? Codec.opusWebM : Codec.aacADTS,
        whenFinished: () {
          setState(() {});
        }
    )
        .then((value) {
      setState(() {});
    });
    print("123"+_mPath!);
    print(await File(_mPath!).readAsBytesSync());

    sendRecord(File(_mPath!), _mPath!);
  }

  void stopPlayer() {
    _mPlayer!.stopPlayer().then((value) {
      setState(() {});
    });
  }

  void goButtonFunction () {
    if (textOfButton[0]+textOfButton[1]+textOfButton[2] == widget.correctWord[widget.id]) {
      print("Correct");
      playDing();
      setState(() {
        correct = true;
      });
    } else {
      playVoice(widget.pathToAudio[widget.id]!);
      print ("Not Correct!");
      everWrong = true;
      resetButtons();
    }
  }


  void playVoice(String ast) async {

    int soundId = await rootBundle.load(ast /*widget.pathToAudio[widget.id]!*/).then((ByteData soundData) {
      return pool.load(soundData);
    });
    int streamId = await pool.play(soundId).whenComplete(() => (){
      if(ast == 'asset/audio/karer.m4a') {
        playVoice(widget.pathToAudio[widget.id]!);
      }
    });
  }


  void resetButtons () async {
    setState((){
      for (var i = 0; i < 3; i++) {
        buttonActivated[i] = true;
        textOfButton[i] = '';
        orbActivated[i] = true;
      }
    });
  }

  void activateButton (i) {
    setState(() {
      for (var j = 0; j < 3; j++) {
        buttonActivated[i] = (buttonActivated[i] && (j == i)); // true & false = false, false & false = false, only true & true = true
      }
    });
  }

  void manageButtonBehaviour (clickButton /*what we clicked*/) {
    bool could = false;
    for (var i = 0; i < 3; i++) {
      if (textOfButton[i] == '') {
        textOfButton[i] = clickButton;
        could = true;
        break;
      }
    }
    if (!could)
      print("could not add any more");

    setState(() {;});
  }

  void doCheck() {
    if (widget.id == 5) {
      WidgetsBinding.instance.addPostFrameCallback( (_) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => GreatJob(corrects: widget.corrects, childId: widget.childId, previousId: 2, myScore: widget.myScore,)));
      });
    }
  }

  Widget starIcon (int indx) {
    return
      Container(
          width: 15,
          height: 15,
          child: widget.corrects[widget.id] == 2? Image.asset('assets/images/litstar.png')
              : widget.corrects[widget.id] == 1? Image.asset('assets/images/emptystar.png')
              : Image.asset('assets/images/emptystar.png')
      );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;



    //showUnableError();
    return Scaffold(
      body: Container(
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
          mainAxisAlignment: MainAxisAlignment.start,
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
            SizedBox(height:5),
            Container (
                width: size.width/1.3,
                height: size.width/1.05,
                child: GestureDetector(
                  onTap: () async{

                  },
                  child: GestureDetector(
                    onTapDown: (_){playVoice(widget.pathToAudio[widget.id]!);},
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Image.asset(widget.pathToImage[widget.id]!)
                      )
                    ),
                  ),
                )
            ),
            (!didFirstRecord)? Container() : Center(
              child: correct ? Container (
                width: size.width/1.3,
                height: size.width/6,
                child: Card(
                  shape: RoundedRectangleBorder (
                    borderRadius: BorderRadius.only(topLeft:Radius.circular(20), topRight:Radius.circular(20), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                  ),
                  child: Center(
                    child: Text(
                        widget.correctWord[widget.id]!
                    ),
                  ),
                ),
              ) : Row (
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DragTarget(
                    builder: (
                        BuildContext _context,
                        List<dynamic> accepted,
                        List<dynamic>rejected) {

                      return Container(
                        width: (size.width/1.3)/3,
                        height: size.width/6,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(topLeft:Radius.circular(20), topRight:Radius.circular(5), bottomLeft: Radius.circular(20), bottomRight: Radius.circular(5)),
                          ),
                          child: Center(child: Text(textOfButton[2])),
                        ),
                      );
                    },
                    onAccept: (List<dynamic> data) {
                      if (textOfButton[2] != '')
                        return;
                      setState(() {
                        textOfButton[2] = data[0];
                        orbActivated[data[1]] = false;
                      });
                    },
                  ),

                  DragTarget(
                    builder: (
                        BuildContext _context,
                        List<dynamic> accepted,
                        List<dynamic>rejected) {

                      return Container(
                        width: (size.width/1.3)/3,
                        height: size.width/6,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(topLeft:Radius.circular(5), topRight:Radius.circular(5), bottomLeft: Radius.circular(5), bottomRight: Radius.circular(5)),
                          ),
                          child: Center(child: Text(textOfButton[1])),
                        ),
                      );
                    },
                    onAccept: (List<dynamic> data) {
                      if (textOfButton[1] != '')
                        return;
                      setState(() {
                        textOfButton[1] = data[0];
                        orbActivated[data[1]] = false;
                      });
                    },
                  ),
                  DragTarget(
                    builder: (
                        BuildContext _context,
                        List<dynamic> accepted,
                        List<dynamic>rejected) {

                      return Container(
                        width: (size.width/1.3)/3,
                        height: size.width/6,
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(topLeft:Radius.circular(5), topRight:Radius.circular(20), bottomLeft: Radius.circular(5), bottomRight: Radius.circular(20)),
                          ),
                          child: Center(child: Text(textOfButton[0])),
                        ),
                      );
                    },
                    onAccept: (List<dynamic> data) {
                      if (textOfButton[0] != '')
                        return;
                      setState(() {
                        textOfButton[0] = data[0];
                        orbActivated[data[1]] = false;
                      });
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 8),

            (!didFirstRecord)? Container() : Center(
              child: correct? Container(
                child: FloatingActionButton (
                  onPressed: (){

                  },
                  backgroundColor: Color(0xFF9459A4),
                  child: Text(
                    'التالي',
                    style: TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ) : Container(
                width: size.width/1.3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Orb(index[0]),
                    Orb(index[1]),
                    Orb(index[2]),
                  ],
                ),
              ),
            ),

            SizedBox(height:8),

            didFirstRecord? Container() : Container(
              width: 50,
              height: 50,
              child: FloatingActionButton(
                onPressed: () {
                  if (isLoading || checkingDuration || !canPlay)
                    return;
                  if (!isRecording) {
                    record();
                    sw.start();

                  } else {
                    stopRecorder();
                    sw.stop();
                    print('trying to update with ${sw.elapsed.inSeconds}');
                    updateDuration(sw.elapsed.inSeconds);
                  }

                  setState((){});
                },
                backgroundColor: Colors.white,
                child: (isLoading || checkingDuration)? CircularProgressIndicator() : Icon(
                  isRecording?CupertinoIcons.pause_solid:CupertinoIcons.mic_solid,
                  color: Color(0xFF9459A4)
                ),
              )
            ),

            didFirstRecord? Container()
              : Column(
                children: [
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Container(
                        width: 80,
                        height: 80,
                        child: Card(

                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(topLeft: Radius.circular(25), bottomLeft: Radius.circular(25), bottomRight: Radius.circular(25), topRight: Radius.circular(2))
                          ),
                          child: Center(
                            child: Text(
                              "كرر",
                              style: TextStyle(
                                fontSize: 35,
                              )
                            ),
                          ),
                        )
                      ),
                      Container(
                        width: 150,
                        height: 150,
                        child: Image.asset(
                          'assets/images/char6.png'
                        ),
                      ),

                    ],

                  ),
                  didFirstRecord? Container() : Container(
                      width: 80,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            didFirstRecord = true;
                          });

                          playVoice('assets/audio/admj.m4a');
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.only(topLeft: Radius.circular(10), bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10), topRight: Radius.circular(10))
                          ),
                          child: Center(
                            child: Text(
                                "تخطي",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                )
                            ),
                          ),
                        ),
                      )
                  ),
                ],
              ),

            (correct || (!didFirstRecord))? Container() : FloatingActionButton(
              foregroundColor: (textOfButton[0]==''||textOfButton[1]==''||textOfButton[2]=='')? Colors.black: Colors.white,
              backgroundColor: (textOfButton[0]==''||textOfButton[1]==''||textOfButton[2]=='')? Colors.white: Color(0xFF9459A4),
              onPressed: goButtonFunction,
              child: Text('أدمج'),
            ),
          ],
        ),
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );

  }
  Widget Orb(int index) {
    return (!orbActivated[index])? Container() : Draggable(
      data: [widget.correctWord[widget.id]![index], index],
      feedback: orbChild(index),
      childWhenDragging: Container(),
      child: orbChild(index),
    );
  }

  Widget orbChild (int index) {
    return Container(
      width: 55,
      height: 55,
      child: FloatingActionButton(
        onPressed: !buttonActivated[index]? (){print("Ok");} : (){},
        child: Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                    colors: [
                      Color(0xFF2BB2E4),

                      Color(0xFFFFD066),
                    ]
                )
            ),
            child: Container(
                width: 55,
                height: 55,
                child: Center(
                  child:Text(
                      widget.correctWord[widget.id]![index],
                      style: TextStyle(
                        color:Colors.white,
                      )
                  ),
                )
            )
        ),
      ),
    );
  }
}
