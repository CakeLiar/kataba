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

class StoreScreen extends StatefulWidget {
  final String childId;
  const StoreScreen({Key? key, required this.childId}) : super(key: key);

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}



class _StoreScreenState extends State<StoreScreen> {

  List<File> images = [];
  List<String> prices  = [];
  List<String> counts  = [];

  var picker = ImagePicker();

  File? image;

  Future<String> transformImage(List<int> imageBytes) async {
    print('tried transforming');
    String base64Image = base64Encode(imageBytes);
    return base64Image;
  }

  static Future<File> base64ToImage (String s) async {
    Uint8List bytes = base64Decode(s!);
    print('bytes: $bytes');
    String dir = (await getApplicationDocumentsDirectory()).path;
    File file = File(
        "$dir/" + DateTime.now().millisecondsSinceEpoch.toString() + ".temp");
    await file.writeAsBytes(bytes);
    print("FILE: ${file.readAsBytesSync()}");
    return file;
  }


  int score = 0;

  void updateScores (int price) async {
    var _firestore = FirebaseFirestore.instance;
    var _auth = FirebaseAuth.instance;

    print('hello');
    int score1 = score;
    print("WHAT YOU GOT");
    print(score1);
    int scorr = (score1 - price).round();
    await _firestore.collection('users').doc(_auth.currentUser?.uid).collection('children').doc(widget.childId).set({
      'score' : scorr
    }, SetOptions(merge: true)).catchError((e){
      print('error: $e');
    });

    score = scorr;

    print('done');
    print(score);
    setState(() {

    });
  }

  void loadItems() async {

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    print('hellowing');
    if (prefs.containsKey('storeImagesList')) {
      print('hellwoing2');
      print(await prefs.getStringList('storeImagesList'));
      print(await prefs.getStringList('storePricesList'));

      List<String> myImagesS = (await prefs.getStringList('storeImagesList')!);
      List<String> myPrices = (await prefs.getStringList('storePricesList')!);
      List<String> myCounts = (await prefs.getStringList('storeCountsList')!);

      List<File> myImagesI = [];
      for (int i = 0; i < myImagesS.length; i++) {
        myImagesI.add(await base64ToImage(myImagesS[i]));
      }
      setState(() {
        images = myImagesI;
        prices = myPrices;
        counts = myCounts;
        print("Images: $images");
        print(myPrices);
      });
    }
  }

  void saveItems() async {
    print('tried saving');
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    List<String> myPrices = prices;
    List<String> myCounts = counts;
    List<String> myImages = [];

    for (int i = 0; i < prices.length; i++) {
      myImages.add(await transformImage(images[i].readAsBytesSync()));
    }

    print(myImages);
    print(myPrices);
    await prefs.setStringList('storeCountsList', myCounts);
    await prefs.setStringList('storeImagesList', myImages);
    await prefs.setStringList('storePricesList', myPrices);
    print('all times');
    print('saved');
  }

  void orderSetState() {
    setState(() {

    });
  }


  void doCheck() async {
    final _firestore = FirebaseFirestore.instance;
    final _auth = FirebaseAuth.instance;


    String score_ = '0';
    await _firestore.collection('users').doc(_auth.currentUser?.uid).collection('children').doc(widget.childId).get().then((value){
      Map<String, dynamic>mp = value.data() as Map<String, dynamic>;
      print(mp['score'].runtimeType);
      score_ = mp['score'].toString();
    });
    setState((){
      score = double.parse(score_).round();
    });
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    doCheck();
    loadItems();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    void showError () {
      TextEditingController priceController = TextEditingController();
      TextEditingController passController = TextEditingController();
      image = null;
      print("hello");
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return StatefulBuilder(
              builder: (context, setState){
                return AlertDialog(
                  title: Text(
                    'أضف منتج',
                    textDirection: TextDirection.rtl,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20.0),
                  ),
                  content: SingleChildScrollView(
                    child: ListBody(
                      children: [
                        image != null? Container(
                            width: 200,
                            height: 200,
                            child: Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                    image!,
                                    fit: BoxFit.fitWidth
                                ),
                              ),
                            )
                        ) : ElevatedButton (
                          onPressed: () async {

                            print("hi");

                            PickedFile? pickedFile = await picker.getImage(
                              source: ImageSource.gallery,
                            );

                            print("tried");

                            if (pickedFile != null) {
                              image = File(pickedFile.path);
                              print("S.A.T");
                              orderSetState();
                              setState(() {

                              });
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)
                            ),
                            elevation: 0,
                            backgroundColor: Color(0xFFDD8D5F),
                          ),
                          child: Text(
                            'أضف صورة',
                            style: TextStyle(
                              color: Colors.white,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'السعر',
                          textDirection: TextDirection.rtl,
                        ),
                        TextField(
                          controller: priceController,
                        ),
                        SizedBox(height: 10),
                        Text(
                          'كلمة المرور',
                          textDirection: TextDirection.rtl,
                        ),
                        TextField(
                          controller: passController,
                        )
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(
                      child: const Text('أضف',
                          style: TextStyle (
                            color: Color(0xFF9459A4),
                          )
                      ),
                      onPressed: () {
                        if (image == null || passController.text != '8184') {
                          print("image null");
                          return;
                        }
                        Navigator.of(context).pop();
                        Future.delayed(Duration(milliseconds: 10), (){
                          setState(() {
                            prices.add(priceController.text);
                            counts.add('0');
                            images.add(image!);
                            saveItems();
                          });
                        } );
                      },
                    ),
                  ],
                );
              }
            );
          }
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFFFFAF0),
      bottomNavigationBar: Container(
        width: size.width,
        height: 80,
        child: Column(
          children: [
            Container(
              width: size.width/1.2,
              child: Card(
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
                        borderRadius: BorderRadius.circular(25)
                    ),
                    child: GestureDetector(
                      onTap: () {
                        showError();
                      },
                      child: Center(
                        child: Text(
                            "أضف جائزة",
                            style: TextStyle(
                              fontSize: 30,
                              color: Colors.white,
                            )
                        ),
                      ),
                    )//declare your widget here
                ),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [

          SizedBox(height:50),

          Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Container (
                  width: 40,
                  height: 40,
                  child: GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop();
                      },
                      child: Icon(
                          CupertinoIcons.chevron_back
                      )
                  ),
                ),
                SizedBox(
                  width: 10,
                ),
                Row(
                  children: [
                    Card(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30)
                        ),
                        child: Padding(
                          padding: EdgeInsets.only(top: 5, bottom: 5, right: 10, left: 10),
                          child: Text(
                              score.toString(),
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.normal,
                                  color: Colors.black
                              )
                          ),
                        )
                    ),
                    Container(
                        width: 40,
                        height: 40,
                        child: Image.asset('assets/images/trophy.png')
                    )
                  ],
                ),
              ]
          ),
          SizedBox(height: 5),

          Text(
              "متجر السعادة",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 35,
              )
          ),
          Container(
            width: size.width/1.5,
            height: size.height/1.5,
            child: ListView.builder(
                shrinkWrap : true,
                physics: AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                padding: EdgeInsets.only(top:0),
                itemCount: images.length,
                scrollDirection: Axis.vertical,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                      width: size.width/1.5,
                      height: size.width/1.5+50,
                      child: Card(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  color: Colors.transparent,
                                  width: 180,
                                  height: 180,
                                  child:ClipRRect(
                                    borderRadius: BorderRadius.circular(30),
                                    child: Image.file(
                                      images[index]!,
                                      fit: BoxFit.fitWidth,
                                    ),
                                  ),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 40,
                                      child: GestureDetector(
                                        onTap: () async {
                                          print('hello world');
                                          if (score >= int.parse(prices[index])) {
                                            print('tried buying item');
                                            SharedPreferences prefs = await SharedPreferences.getInstance();
                                            var r = await prefs.getStringList('storeCountsList');
                                            r![index] = (int.parse(counts[index])+1).toString();
                                            await prefs.setStringList('storeCountsList', r);

                                            counts = r!;
                                            updateScores(int.parse(prices[index]));
                                          } else {
                                            /// Show Dialog (Can't buy)
                                          }
                                        },
                                        child: Icon(
                                          CupertinoIcons.plus,
                                        ),
                                      ),
                                    ),
                                    Container(
                                        width: 80,
                                        height: 40,
                                        child: Center(
                                          child: Text(
                                            prices[index].toString(),
                                            style: TextStyle(
                                                color: Color(0xFF9459A4)
                                            ),
                                          ),
                                        )
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    Container(
                                        width: 30,
                                        height: 40,
                                        child: Center(
                                          child: Text(
                                            counts[index].toString(),
                                            style: TextStyle(
                                                color: Color(0xFFDD8D5F)
                                            ),
                                          ),
                                        )
                                    ),
                                    Container(
                                        width: 60,
                                        height: 40,
                                        child: Center(
                                          child: Text(
                                            'أملك:',
                                            textDirection: TextDirection.rtl,
                                            style: TextStyle(
                                                color: Colors.black
                                            ),
                                          ),
                                        )
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                      )
                  );
                }
            ),
          ),

          SizedBox(height: 10),
        ],
      ),
    );
  }
}
