import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soundpool/soundpool.dart';

class SoundRecorder extends StatefulWidget {
  const SoundRecorder({Key? key}) : super(key: key);

  @override
  State<SoundRecorder> createState() => _SoundRecorderState();
}

class _SoundRecorderState extends State<SoundRecorder> {
  final recorder = FlutterSoundRecorder();
  String? s2tToken = null;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initRecorder();

    login().then((value) {
      var token = ((json.decode(value.body)) as Map<String, dynamic>)['message'];
      var status = ((json.decode(value.body)) as Map<String, dynamic>)['status'];

      if (status=='OK') {
        print('Connected to S2T server');
        s2tToken = token;
      } else {
        print("BAD REQUEST");
      }
    });
  }

  Future initRecorder() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw 'Microphone permission not granted';
    }
    await recorder.openRecorder();

    recorder.setSubscriptionDuration(Duration(microseconds: 500));
  }

  Future record() async {
    final loc = await getApplicationDocumentsDirectory();
    await recorder.startRecorder(toFile: loc.path+'/audio');
  }


  Future stop () async {
    print("Stopping");
    final path = await recorder.stopRecorder();
    print(path!);
    sendRecord(path!);
    Soundpool pool = Soundpool(streamType: StreamType.music);
    int soundId = await rootBundle.load(path!).then((ByteData soundData) {
      return pool.load(soundData);
    });
    int streamId = await pool.play(soundId);
    print(streamId);
    print("HALLJLUIJA");
  }

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

  void sendRecord(String audioFilePath) async {

    print("preparing send");

    var request = MultipartRequest("POST", Uri.parse("https://px.kateb.ai:4040/api/recognize-file"));
    request.headers.addAll({
      'Authorization' : 'Bearer $s2tToken',
      'Content-Type': 'multipart/form-data',
    });
    request.files.add(await MultipartFile.fromPath(
        'package',
        audioFilePath
    ));
    request.send().then((response) async {
      if (response.statusCode == 200)
        print("Uploaded!");

      print(await response.stream.bytesToString());
      print(response.statusCode);
    }).catchError((e){
      print(e);
    });

    print("hi");

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          child: Icon(
            recorder.isRecording ? Icons.stop : Icons.mic,
            size: 80
          ),
          onPressed: () async{
            if (recorder.isRecording) {
              await stop();
            } else {
              await record();
            }
          },
        )
      )
    );
  }
}
