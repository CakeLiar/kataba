import 'dart:convert';
import 'dart:typed_data';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
import 'package:google_speech/google_speech.dart';
import 'package:google_speech/speech_client_authenticator.dart';

import 'package:trying_flutter_sound/MiniGameTemplate.dart';
import 'package:trying_flutter_sound/Slider.dart' as slider;
import 'Slider.dart';


class MiniGame extends StatefulWidget {

  final int id;
  final List<double> corrects;
  final int level;
  final String childId;
  final myScore;

  final List<String> pathToImage = ['assets/images/tamr.png', 'assets/images/bnt.png', 'assets/images/habl.png', 'assets/images/klb.png', 'assets/images/lahm.png'];
  final List<String> pathToAudio = ['assets/audio/tamr.m4a', 'assets/audio/bnt.m4a', 'assets/audio/habl.m4a', 'assets/audio/klb.m4a', 'assets/audio/lahm.m4a'];
  final List<String> correctWord = ['تمر', 'بنت', 'حبل', 'كلب', 'لحم'];

  MiniGame({required this.id, required this.level, required this.corrects, required this.childId, required this.myScore});

  @override
  State<MiniGame> createState() => _MiniGameState();
}

const theSource = AudioSource.microphone;


class _MiniGameState extends State<MiniGame> {

  List<bool> buttonActivated = [true, true, true];
  List<String> textOfButton = ['', '', ''];
  List<bool> orbActivated =  [true, true, true];
  bool everWrong = false;
  List<int> index = [0, 1, 2];
  List<bool> isFalse = [false, false, false];
  double valueOfBall = 1;
  bool dingedTheSemiFinalDing = false;
  bool startedSlider = false;

  String randomAddition = DateTime.now().microsecond.toString();

  Soundpool pool = Soundpool.fromOptions(options: SoundpoolOptions());


  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mplaybackReady = false;
  String? s2tToken = null;
  double resetSlider = 0;
  bool timed = false;


  double instructionStep = 0;
  List<bool>playedOrb = [false, false, false];


  Codec _codec = Codec.pcm16WAV;
  String? _mPath = /*'tau_file.mp4'*/null;

  bool isRecording = false;
  bool isLoading = false;

  bool correct = false;

  bool didFirstRecord = false;

  final Map<String, String> arabicToMedia = {
    'ت' : 'assets/letters/t.m4a',
    'ف' : 'assets/letters/f.m4a',
    'ح' : 'assets/letters/h.m4a',
    'ل' : 'assets/letters/l.m4a',
    'م' : 'assets/letters/m.m4a',
    'ر' : 'assets/letters/r.m4a',
    'أ' : 'assets/letters/a.m4a',
    'ا' : 'assets/letters/a.m4a',
    'ب' : 'assets/letters/b.m4a',
    'ك' : 'assets/letters/k.m4a',
    'ن' : 'assets/letters/n.m4a',
    'ز' : 'assets/letters/z.m4a',
  };

  Stopwatch sw = Stopwatch();

  bool canPlay = false;

  bool checkingDuration = false;

  Future<void> showUnableError () async {
    await showDialog(
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



    await _firestore.collection('users').doc(_auth.currentUser!.uid).collection('children').doc(widget.childId).get().then((value) async {
      Map<String, dynamic> mp = value.data() as Map<String, dynamic>;
      if (mp['voiceDuration${DateTime.now().year.toString()+DateTime.now().month.toString()+DateTime.now().day.toString()}'] == null) {
        print("Can");
        setState(() {
          canPlay = true;
        });
      } else if (mp['voiceDuration${DateTime.now().year.toString()+DateTime.now().month.toString()+DateTime.now().day.toString()}'] > 3*60) {
        await showUnableError().then((_){
          Navigator.of(context).pop();
        });
        print('can\'t because cloud time is more than 10');
        print(mp['voiceDuration${DateTime.now().year.toString()+DateTime.now().month.toString()+DateTime.now().day.toString()}']);
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
      _dur = mp['voiceDuration${DateTime.now().year.toString()+DateTime.now().month.toString()+DateTime.now().day.toString()}'];
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
      'voiceDuration${DateTime.now().year.toString()+DateTime.now().month.toString()+DateTime.now().day.toString()}' : rr    }, SetOptions(merge: true)).then((v){
      print('saved duration');
      print(_dur! + currDur);
    }).catchError((e) {
      print("couldn't save");
    });
  }


  void playLetter (String pathh) async {
    FlutterSoundPlayer fps = FlutterSoundPlayer();
    fps.startPlayer();



    int soundId = await rootBundle.load(pathh).then((ByteData soundData) {
      return pool.load(soundData);
    });
    int streamId = await pool.play(soundId);
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

  void processResultG (String res) {
    res = res.replaceAll('أ', 'ا');

    if (instructionStep != 4) {
      setState((){
        didFirstRecord = true;
      });
      setState((){
        instructionStep = 1.5;
      });
    } else {
      var r = widget.corrects;
      if (!everWrong) {
        r[widget.id] = 2;
      } else {
        r[widget.id] = 1;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MiniGame(id: widget.id+1, level: widget.level, corrects: r, childId: widget.childId, myScore: widget.myScore),
        ),
      );
    }

    bool did = false;

    if (res.length < 2) {
      print("Empty voice");
      playVoice('assets/audio/karer.m4a');

      if (instructionStep == 4) {
        print("instructionStep4 is wrong");
        setState(() {
          instructionStep = 3;
          correct = true;
        });
        var r = widget.corrects;
        if (!everWrong) {
          r[widget.id] = 2;
        } else {
          r[widget.id] = 1;
        }

        startedSlider = false;
        return;
      }
      return;
    }

    if (res.contains(widget.correctWord[widget.id]) || widget.correctWord[widget.id].contains(res)) {
      print('Correct!');
      playDing();
      setState((){
        didFirstRecord = true;
      });
      did = true;
    } else {
      print ('$res is wrong');
      print(res.length == widget.correctWord[widget.id].length);
      if (res.length == widget.correctWord[widget.id].length) {
        print (stringDistance(res, widget.correctWord[widget.id]));
        if (stringDistance(res, widget.correctWord[widget.id])! <= 1) {
          print('Correct!');
          playDing();
          setState((){
            didFirstRecord = true;
          });
          did = true;
        }
      }
    }
    if (!did) {
      print ('instructionstep4 is $instructionStep');
      if (instructionStep == 4) {
        print("instructionStep4 is wrong");
        setState(() {
          instructionStep = 3;
          correct = true;
        });
        startedSlider = false;
        return;
      }
      print("Empty voice");
      playVoice('asset/audio/karer.m4a');
    } else {
      if (instructionStep == 4) {
        var r = widget.corrects;
        if (!everWrong) {
          r[widget.id] = 2;
        } else {
          r[widget.id] = 1;
        }
        print ('my r is $r');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MiniGame(id: widget.id+1, level: widget.level, corrects: r, childId: widget.childId, myScore: widget.myScore,),
          ),
        );
        return;
      }
      setState((){
        instructionStep = 1.5;
      });
    }
  }

  void processResult (String res) {
    Map<String, dynamic> mp = json.decode(res);
    print(mp);



    if (instructionStep == 4) {
      var r = widget.corrects;
      if (!everWrong) {
        r[widget.id] = 2;
      } else {
        r[widget.id] = 1;
      }
      print ('my r is $r');
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MiniGame(id: widget.id+1, level: widget.level, corrects: widget.corrects, childId: widget.childId, myScore: widget.myScore,),
        ),
      );
      return;
    }

    final List<dynamic> finalWords = mp['Text_String'];

    print(finalWords);

    print(finalWords.runtimeType);

    print(finalWords[0]['text']);

    print ("About to print results");
    print ("instruction step: $instructionStep");
    bool did = false;
    for (var i in finalWords) {
      if (i['text'].toString().contains(widget.correctWord[widget.id]) || widget.correctWord[widget.id].contains(i['text'].toString())) {
        print('Correct!');
        Future.delayed(Duration(seconds: 2), (){
          setState((){
            didFirstRecord = true;
          });
          did = true;
        });
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
      if (instructionStep == 4) {
        print("Empty voice");
        setState(() {
          instructionStep = 3;
          correct = true;
        });
        var r = widget.corrects;
        if (!everWrong) {
          r[widget.id] = 2;
        } else {
          r[widget.id] = 1;
        }
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => MiniGame(id: widget.id+1, level: widget.level, corrects: widget.corrects, childId: widget.childId, myScore: widget.myScore,),
          ),
        );
        return;
      }
      print("Empty voice");
      playVoice('asset/audio/karer.m4a');
    } else {
      if (instructionStep == 4) {
        print ("SHOULD FINISH");
      }
      instructionStep = 1.5;
    }
  }

  void sendRecordToGoogle(File file, String pathh) async {

    print ("My file: ${File('assets/test_service_account.json')}");

    print ("My file: ${file}");

    String r = (await rootBundle.loadString('assets/test_service_account.json'));
    print (r);

    print("${await file.length()}, 123123");
    print(await file.readAsBytesSync());

    setState((){

      isLoading = true;
    });

    final config = RecognitionConfig(
      encoding: AudioEncoding.LINEAR16,
      model: RecognitionModel.basic,
      enableAutomaticPunctuation: false,
      languageCode: 'ar-XA',
      sampleRateHertz: 16000,
      audioChannelCount: 1
    );


    final audio = file.readAsBytesSync();

    final serviceAccount = ServiceAccount.fromString(
        '${(await rootBundle.loadString('assets/test_service_account.json'))}');
    final speechToText = SpeechToText.viaServiceAccount(serviceAccount);

    print("recognizingg");

    await speechToText.recognize(config, audio).then((value) {
      setState(() {

        print ("GETTING: value.results");
        try {
          var text = value.results
              .map((e) => e.alternatives.first.transcript)
              .join('\n');

          print ('results: $text <-');
          processResultG(text);
        } catch (e) {
          processResultG('');
        }
      });
    }).whenComplete(() => setState(() {
      print("hiii");
      isLoading = false;
    }));


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
    print("gettingPath");
    final loc = await getApplicationDocumentsDirectory();

    _mPath = loc.path+'/$randomAddition\_tau_file.wav';
    print(_mPath);
    print("Audio Path: $_mPath");
  }



  @override
  void initState() {

    doCheck();
    Future.delayed(Duration(milliseconds: 10), () {
      checkDuration();
    });
    Future.delayed(Duration(milliseconds: 10), () {
      setState(() {
        timed = true;
      });
    });


    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });

    index.shuffle();

    initPath();
    /*login().then((value) {
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
    }); */

    openTheRecorder().then((value) {
      setState(() {
        _mRecorderIsInited = true;
      });
      print ("opened the recorder successfully");
    });
    playVoice(widget.pathToAudio[widget.id]);
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
      _mPath = '$randomAddition\_tau_file.wav';
      if (!await _mRecorder!.isEncoderSupported(_codec) && kIsWeb) {
        _mRecorderIsInited = true;

        print ('no error what the heck');
        return;
      }
    } else {
      print("ERROR WHAT THE HECK");
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
    print("tried recording with status: ${isRecording}");
    if (isRecording == true) {
      print("CAUGHT EXCEPTION");
      return;
    }
    _mRecorder!
        .startRecorder(
      toFile: _mPath,
      codec: _codec,
      sampleRate: 16000,
      numChannels: 1,
      audioSource: theSource,

    )
        .then((value) {
      setState(() {
        isRecording = true;
        print("Started Recording $isRecording");
      });
    }).catchError((e){
      print ('error starting the recording ${e}');
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
      });
    }).catchError((e) {
      print("ERROR STOPPING THE RECORDER: ${e}");
    });


    print("123"+_mPath!);
    print(await File(_mPath!).readAsBytesSync());

    //sendRecord(File(_mPath!), _mPath!);
    sendRecordToGoogle(File(_mPath!), _mPath!);
    //play();
  }

  Future<void> play() async {
    assert(_mPlayerIsInited &&
        _mplaybackReady &&
        _mRecorder!.isStopped &&
        _mPlayer!.isStopped);
    _mPlayer!
        .startPlayer(
        fromURI: _mPath,
        codec: _codec,
        //codec: kIsWeb ? Codec.opusWebM : Codec.aacADTS,
        whenFinished: () {
          setState(() {});
        }
    )
        .then((value) {
      setState(() {});
    });
  }

  void stopPlayer() {
    _mPlayer!.stopPlayer().then((value) {
      setState(() {});
    });
  }

  void goButtonFunction () {
    if (textOfButton[0]+textOfButton[1]+textOfButton[2] == widget.correctWord[widget.id]) {
      print("Correct");

      Future.delayed(Duration(seconds:1, milliseconds: 500), (){
        playDing();
        setState(() {
          correct = true;
        });
      });
    } else {
      print ("Not Correct!");
      playVoice(widget.pathToAudio[widget.id]!);
      everWrong = true;
      resetButtons();
    }
  }

  void playVoice(String ast) async {

    int soundId = await rootBundle.load(ast).then((ByteData soundData) {
      return pool.load(soundData);
    });
    print (ast);
    int streamId = await pool.play(soundId).whenComplete(() => (){
      print ('finished playing audio');
      if(ast == 'assets/audio/jaze.m4a') {
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
        child: widget.corrects[indx-1] == 2.0? Image.asset('assets/images/litstar.png')
            : widget.corrects[indx-1] == 1.0? Image.asset('assets/images/unlitstar.png')
            : Image.asset('assets/images/emptystar.png')
    );
  }

  void giveError(int index) {
    setState((){
      isFalse[index] = true;
    });
    Future.delayed(Duration(seconds: 2), (){
      setState((){
        isFalse[index] = false;
        everWrong = true;
      });
    });
    return;
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    doCheck();

    if (textOfButton[0] !='' && textOfButton[1] !='' && textOfButton[2] !='' && !dingedTheSemiFinalDing) {
      dingedTheSemiFinalDing = true;
      goButtonFunction();
    }
    if (instructionStep == 0) {
      playVoice('assets/audio/karer.m4a');
      Future.delayed(Duration(seconds: 3), () {playVoice(widget.pathToAudio[widget.id]);});
      Future.delayed(Duration.zero, () {showInstruction(context, size, 0);});
      instructionStep = 1;
    }
    if (instructionStep == 1.5) {
      playVoice('assets/audio/jaze.m4a');
      Future.delayed(Duration.zero, () {showInstruction(context, size, 0.5);});
      instructionStep = 2;
    }
    if (instructionStep == 2 && playedOrb[0] && playedOrb[1] && playedOrb[2]) {
      instructionStep = 2.1;
      Future.delayed(Duration(seconds: 1), (){
        playVoice('assets/audio/ashb.m4a');
        Future.delayed(Duration.zero, () {showInstruction(context, size, 1);});
        instructionStep = 3;
      });
    }
    if (instructionStep == 3 && correct) {
      playVoice('assets/audio/admj.m4a');
      Future.delayed(Duration.zero, () {showInstruction(context, size, 2);});
      instructionStep = 4;
    }

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
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
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
                        onTapDown: (_){playVoice(widget.pathToAudio[widget.id]);},
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
                (!didFirstRecord )? Container() : Center(
                  child: (correct && false) ? Container (
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
                  ) : BlurFilter(
                    sigmaX: instructionStep <= 2? 2: 0,
                    sigmaY: instructionStep <= 2? 2: 0,
                    child: Row (
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

                                child: Center(child:
                                textOfButton[2]!=''? Container(width: 30, height:30, child:Center(
                                  child:Text(
                                      widget.correctWord[widget.id]![2],
                                      style: TextStyle(
                                        color:Colors.black,
                                      )
                                  ),
                                )) //orbChild(2)
                                    : isFalse[2]? Container(width: 30, height:30, child:Image.asset('assets/images/error.png'))
                                    : Container()
                                ),
                              ),
                            );
                          },
                          onAccept: (List<dynamic> data) {
                            if (textOfButton[2] != '')
                              return;
                            if (data[0] == widget.correctWord[widget.id][2]) {
                              print("yay correct");
                              playDing();
                            } else {
                              giveError(2);
                              return;
                            }
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
                                child: Center(child:
                                textOfButton[1]!=''?   Container(width: 30, height:30, child:Center(
                                  child:Text(
                                      widget.correctWord[widget.id]![1],
                                      style: TextStyle(
                                        color:Colors.black,
                                      )
                                  ),
                                )) //orbChild(1)
                                    : isFalse[1]? Container(width: 30, height:30, child:Image.asset('assets/images/error.png'))
                                    : Container()
                                ),

                              ),
                            );
                          },
                          onAccept: (List<dynamic> data) {
                            if (textOfButton[1] != '')
                              return;
                            if (data[0] == widget.correctWord[widget.id][1]) {
                              print("yay correct");
                              playDing();
                            } else {
                              giveError(1);
                              return;
                            }
                            print ('${data[0]}, and ${widget.correctWord[1]}');
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
                                child: Center(child:
                                textOfButton[0]!=''?  Container(width: 30, height:30, child:Center(
                                  child:Text(
                                      widget.correctWord[widget.id]![0],
                                      style: TextStyle(
                                        color:Colors.black,
                                      )
                                  ),
                                ))  //orbChild(0)
                                    : isFalse[0]? Container(width: 30, height:30, child:Image.asset('assets/images/error.png'))
                                    : Container()
                                ),
                              ),
                            );
                          },
                          onAccept: (List<dynamic> data) {
                            if (textOfButton[0] != '')
                              return;
                            if (data[0] == widget.correctWord[widget.id][0]) {
                              print("yay correct");
                              playDing();
                            } else {
                              giveError(0);
                              return;
                            }
                            setState(() {
                              textOfButton[0] = data[0];
                              orbActivated[data[1]] = false;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 8),

                (!didFirstRecord)? Container(
                  width: size.width /1.3,
                  height: 60,
                  child: Card(
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)
                    ),
                    child: Center(
                      child: Text(
                        widget.correctWord[widget.id],
                        style: TextStyle(
                          fontSize: 20,
                        )
                      ),
                    )
                  ),
                ) : Center(
                  child: (correct && false)? Container(
                    child: FloatingActionButton (
                      onPressed: (){
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (context) => MiniGame(id: widget.id+1, level: widget.level, corrects: widget.corrects, childId: widget.childId, myScore: widget.myScore,),
                          ),
                        );
                      },
                      child: Text('Next'),
                    ),
                  ) : Container(
                    width: size.width/1.3,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        (playedOrb[index[2]])?Orb(index[2]):orbChild(index[2]),

                        (playedOrb[index[1]])?Orb(index[1]):orbChild(index[1]),

                        (playedOrb[index[0]])?Orb(index[0]):orbChild(index[0]),
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
                      if(isLoading || checkingDuration || !canPlay) {
                        return;
                      }
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
                    child: isLoading? CupertinoActivityIndicator() : Icon(
                      isRecording?CupertinoIcons.pause_solid:CupertinoIcons.mic_solid,
                      color: Color(0xFF9459A4)
                    ),
                  )
                ),

                didFirstRecord? Container()
                  : Column(
                    children: [
                      SizedBox(height: 20),

                    ],
                  ),

                /*(correct || (!didFirstRecord))? Container() : FloatingActionButton(
                  foregroundColor: (textOfButton[0]==''||textOfButton[1]==''||textOfButton[2]=='')? Colors.black: Colors.white,
                  backgroundColor: (textOfButton[0]==''||textOfButton[1]==''||textOfButton[2]=='')? Colors.grey: Color(0xFF9459A4),
                  onPressed: goButtonFunction,
                  child: Text('أدمج'),
                ),*/


                /// SKIP FIRST RECORDING BUTTON

                /*didFirstRecord? Container() : Container(
                    width: 80,
                    height: 40,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          didFirstRecord = true;
                        });

                        playVoice('assets/audio/jaze.m4a');

                        instructionStep = 1.5;
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
                              )
                          ),
                        ),
                      ),
                    )
                ),
                 */
              ],
            ),



            Padding(
              padding: const EdgeInsets.only(bottom: 30.0),
              child: Container(
                height: 50,
                child: slider.Slider( isLoading: isLoading, value: resetSlider, instructionStep: instructionStep, orbBackgroundColor: Color(0xFF2BB2E4),  valueChanged: (double value) async {
                  if (resetSlider == 1) {
                    Future.delayed(Duration.zero, (){setState(() {
                      setState(() {
                        resetSlider = 0;
                      });
                    });});
                  }

                  if (value <= 1 && !startedSlider && timed) {

                    startedSlider = true;
                    correct = false;
                    randomAddition = DateTime.now().microsecond.toString();

                    print("LET'S RECORD");

                    record();

                    print('started recording by slider');
                  }
                  if (value < 0.15 && isRecording) {
                    print ('hellowinggg');
                    isRecording = false;
                    setState((){
                      resetSlider = 1;
                    });
                    stopRecorder();
                  }
                })
              ),
            ),
          ],
        ),
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );

  }

  Widget Ball() {
    return Container(
      width: 42,
      height: 42,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(360)
        ),
        color: Color(0xFFFFD066),
        child: Container(
          width: 28,
          height: 28,
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(360)
            ),
            color: Color(0xFFEA5753)
          )
        )
      )
    );
  }

  Widget Orb(int indx) {

    print("instruction Step: $instructionStep");
    if (instructionStep == 2) {
      print (playedOrb[indx]);
      return orbChild(indx, placed: !playedOrb[indx]);
    }
    return (!orbActivated[indx])? Container() : Draggable(
      data: [widget.correctWord[widget.id]![indx], indx],
      feedback: orbChild(indx, placed: false),
      childWhenDragging: Container(),

      child: orbChild(indx, placed: false),
    );
  }

  Widget orbChild (int indx, {bool placed= true, bool cross= false}) {
    return Container(
      width: 55,
      height: 55,
      child: FloatingActionButton(
        onPressed: !buttonActivated[indx]? (){print("Ok");} : () {
          setState(() {
            print("Played Orb: $indx with index ${index[indx]}");
            playedOrb[indx] = true;
          });
          if (widget.correctWord[widget.id] == 'بنت' && indx == 2)
            playLetter('assets/audio/tt.m4a');
          else if (widget.correctWord[widget.id] == 'لحم' && indx == 0)
            playLetter('assets/audio/la.m4a');
          else
            playLetter(arabicToMedia[widget.correctWord[widget.id]![indx]]!);
        },
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                Color(placed == false? 0xFF2BB2E4 : 0xFF000000).withOpacity(placed==true?0.6:1),

                Color(placed == false? 0xFFFFD066 : 0xFFB4B4B4).withOpacity(placed==true?0.1:1),
              ]
            )
          ),
          child: Container(
            width: 55,
            height: 55,
            child: Center(
              child:Text(
                  widget.correctWord[widget.id]![indx],
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
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

