import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'dart:convert';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:flutter_sound_platform_interface/flutter_sound_recorder_platform_interface.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:uri_to_file/uri_to_file.dart';
import 'package:soundpool/soundpool.dart';
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';

/*
 * This is an example showing how to record to a Dart Stream.
 * It writes all the recorded data from a Stream to a File, which is completely stupid:
 * if an App wants to record something to a File, it must not use Streams.
 *
 * The real interest of recording to a Stream is for example to feed a
 * Speech-to-Text engine, or for processing the Live data in Dart in real time.
 *
 */

///
typedef _Fn = void Function();

/* This does not work. on Android we must have the Manifest.permission.CAPTURE_AUDIO_OUTPUT permission.
 * But this permission is _is reserved for use by system components and is not available to third-party applications._
 * Pleaser look to [this](https://developer.android.com/reference/android/media/MediaRecorder.AudioSource#VOICE_UPLINK)
 *
 * I think that the problem is because it is illegal to record a communication in many countries.
 * Probably this stands also on iOS.
 * Actually I am unable to record DOWNLINK on my Xiaomi Chinese phone.
 *
 */
//const theSource = AudioSource.voiceUpLink;
//const theSource = AudioSource.voiceDownlink;

const theSource = AudioSource.microphone;

/// Example app.
class SimpleRecorder extends StatefulWidget {
  @override
  _SimpleRecorderState createState() => _SimpleRecorderState();
}

class _SimpleRecorderState extends State<SimpleRecorder> {
  Codec _codec = Codec.aacMP4;
  String? _mPath = /*'tau_file.mp4'*/null;
  String pathToImage = 'assets/images/door1.jpg';
  String pathToAudio = 'assets/audio/door1.mp3';
  FlutterSoundPlayer? _mPlayer = FlutterSoundPlayer();
  FlutterSoundRecorder? _mRecorder = FlutterSoundRecorder();
  bool _mPlayerIsInited = false;
  bool _mRecorderIsInited = false;
  bool _mplaybackReady = false;
  String? s2tToken = null;

  List<bool> buttonActivated = [true, true, true];
  List<String> textOfButton = ['', '', ''];
  List<String> correctCharacter = ['الباء', 'الألف', 'الباء'];
  List<bool> isRecordings = [false, false, false];
  List<bool> isLoading = [false, false, false];
  String correctWord = 'باب';
  bool everWrong = false;

  bool correct = false;

  Future<Response> login() {
    return true?
    post(
      Uri.parse("https://px.kateb.ai:4040/api/login?email=ali.g.saoud@gmail.com&apiKey=109c7439a15945cba31c03627ba737a5"),
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

  void processResult (String res, int index) {
    Map<String, dynamic> mp = json.decode(res);
    print(mp);

    final List<dynamic> finalWords = mp['Text_String'];

    print(finalWords);

    print(finalWords.runtimeType);

    print(finalWords[0]['text']);

    print ("About to print results");
    bool did = false;
    for (var i in finalWords) {
      if (i['text'] == correctCharacter[index]) {
        print('Correct!');
        textOfButton[index] = i['text'];
      }
    }
    if (!did) {
      print("Empty voice");
    }
  }

  void sendRecord(File file, String pathh, int index) async {
    print("${await file.length()}, 123123");
    print(await file.readAsBytesSync());

    isLoading[index] = true;

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
    if (res.statusCode != 200) throw Exception('http.post error: statusCode= ${res.statusCode}');

    final finalResponse = await res.stream.bytesToString();

    print(finalResponse);


    print("hiii");
    setState((){
      isLoading[index] = false;
    });

    processResult(finalResponse, index);

  }

  void initPath () async {
    final loc = await getApplicationDocumentsDirectory();
    _mPath = loc.path+'/tau_file.mp4';
  }

  @override
  void initState() {
    playVoice();
    _mPlayer!.openPlayer().then((value) {
      setState(() {
        _mPlayerIsInited = true;
      });
    });

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

  void record(int index) {
    _mRecorder!
        .startRecorder(
      toFile: _mPath,
      codec: _codec,
      audioSource: theSource,
    )
        .then((value) {
      setState(() {});
    });
  }

  void stopRecorder(int index) async {
    await _mRecorder!.stopRecorder().then((value) {
      setState(() {
        //var url = value;
        _mplaybackReady = true;
      });
    });
    play(index);
  }

  Future<void> play(int index) async {
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

    sendRecord(File(_mPath!), _mPath!, index);
  }

  void stopPlayer() {
    _mPlayer!.stopPlayer().then((value) {
      setState(() {});
    });
  }

// ----------------------------- UI --------------------------------------------

  void goButtonFunction () {
    if (textOfButton[0] == '' || textOfButton[1] == '' || textOfButton[2] == '')
      //return;
    setState(() {
      correct = true;
    });
    /*Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SimpleRecorder(),
      ),
    );*/
  }

  void playVoice() async {
    print('tried playing voice');
    Soundpool pool = Soundpool(streamType: StreamType.music);

    int soundId = await rootBundle.load(pathToAudio).then((ByteData soundData) {
      return pool.load(soundData);
    });
    int streamId = await pool.play(soundId);
    print(streamId);
    print('hello');
  }


  void resetButtons () async {
    setState((){
      for (var i = 0; i < 3; i++) {
        buttonActivated[i] = true;
        textOfButton[i] = '';
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

    for (var i = 0; i < 3; i++) {
      if (clickButton != i)
        isRecordings[i] = false;
    }
    if (!isRecordings[clickButton]) {
      isRecordings[clickButton] = true;
      // TODO: Start Recording

      record(clickButton);
    } else {
      isRecordings[clickButton] = false;
      // TODO: Stop Recording
      stopRecorder(clickButton);
    }
    setState(() {;});
  }

  @override
  Widget build(BuildContext context) {

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: Column(

          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container (
                width: size.width/1.3,
                height: size.height/3,
                child: GestureDetector(
                  onTap: () async{
                    playVoice();
                  },
                  child: Card(
                      child: Center(
                        child: Image.asset(pathToImage)
                      )
                  ),
                )
            ),
            Center(
              child: correct ? Container (
                width: 3*size.width/5,
                height: size.width/6,

                child: Card(
                  child: Center(
                    child: Text(
                        correctWord
                    ),
                  ),
                ),
              ) : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: size.width/5,
                    height: size.width/6,
                    child: Card(

                      color: (textOfButton[0] != ''? Colors.greenAccent : Colors.white),
                      child: Center(child: Text(textOfButton[0])),
                    ),
                  ),
                  Container(
                    width: size.width/5,
                    height: size.width/6,
                    child: Card(
                      color: (textOfButton[1] != ''? Colors.greenAccent : Colors.white),
                      child: Center(child: Text(textOfButton[1])),
                    ),
                  ),
                  Container(
                    width: size.width/5,
                    height: size.width/6,
                    child: Card(
                      color: (textOfButton[2] != ''? Colors.greenAccent : Colors.white),
                      child: Center(child: Text(textOfButton[2])),
                    ),
                  )
                ],
              ),
            ),

            Center(
              child: correct? Container(
                child: FloatingActionButton (
                  onPressed: (){
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SimpleRecorder(),
                      ),
                    );
                  },
                  child: Text('Next'),
                ),
              ) : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FloatingActionButton(
                    onPressed: !buttonActivated[0]? (){print("Ok");} : (){
                      if (!isLoading[0])
                        manageButtonBehaviour(0);
                    },
                    child: isRecordings[0]? Icon(
                        Icons.pause_outlined
                    ) : (isLoading[0]? CircularProgressIndicator(color: Colors.black) : Icon(Icons.mic)),
                  ),
                  FloatingActionButton(
                    onPressed: !buttonActivated[1]? (){print("Ok");} : (){
                      if (!isLoading[1])
                        manageButtonBehaviour(1);
                    },
                    child: isRecordings[1]? Icon(
                        Icons.pause_outlined
                    ) : (isLoading[1]? CircularProgressIndicator(color: Colors.black) : Icon(Icons.mic)),
                  ),
                  FloatingActionButton(
                    onPressed: !buttonActivated[2]? (){print("Ok");} : (){
                      if (!isLoading[2])
                        manageButtonBehaviour(2);
                    },
                    child: isRecordings[2]? Icon(
                        Icons.pause_outlined
                    ) : (isLoading[2]? CircularProgressIndicator(color: Colors.black) : Icon(Icons.mic)),
                  ),
                ],
              ),
            ),

            correct? Container() : FloatingActionButton(

              onPressed: goButtonFunction,
              child: Text('GO'),
            ),
          ],
        ),
      ),// This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}