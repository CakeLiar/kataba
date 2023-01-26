import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'MiniGameTemplate.dart';

class Slider extends StatefulWidget {
  final ValueChanged<double> valueChanged;
  double value;
  bool isLoading = false;
  double instructionStep;
  Color orbBackgroundColor;

  Slider({required this.isLoading, required this.valueChanged, required this.value, required this.instructionStep, required this.orbBackgroundColor});

  @override
  SliderState createState() {
    return new SliderState();
  }
}

class SliderState extends State<Slider> {
  ValueNotifier<double> valueListener = ValueNotifier(.0);
  @override
  void initState() {

    valueListener.addListener(notifyParent);
    valueListener.value = 1;
    super.initState();
  }

  void notifyParent() {
    if (widget.valueChanged != null) {
      widget.valueChanged(valueListener.value);
    }
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
                    color: widget.orbBackgroundColor
                )
            )
        )
    );
  }

  double abs(double x) {
    return (x>0)? 0 : x;
  }

  bool nono = true;
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      valueListener.value = 1;
    } else if (widget.value == 1 && nono) {
      valueListener.value = 1;
      nono = false;
    } else if (widget.value == 0){
      nono = true;
    }
    return BlurFilter(

      sigmaX: widget.instructionStep==4?0.0:2.0,
      sigmaY: widget.instructionStep==4?0.0:2.0,
      child: Container(
        height: 50.0,
        padding: EdgeInsets.symmetric(horizontal: 40.0),
        child: Card(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(360)
          ),
          child: Stack(
            children: [
              Container(
                width: 50,
                height: 50,
                child: widget.isLoading? Container(width: 50, height: 50, child: CupertinoActivityIndicator(color: Colors.black)) : Icon(
                    CupertinoIcons.mic
                ),
              ),
              Builder(
                builder: (context) {
                  final handle = GestureDetector(
                    onHorizontalDragUpdate: (details) {
                      if (widget.isLoading == true || widget.instructionStep != 4) {
                        return;
                      }
                      valueListener.value = (valueListener.value +
                          abs(details.delta.dx) / context.size!.width)
                          .clamp(.0, 1.0);
                    },
                    child: Ball(),
                  );

                  return AnimatedBuilder(
                    animation: valueListener,
                    builder: (context, child) {
                      return Align(
                        alignment: Alignment(valueListener.value * 2 - 1, .5),
                        child: child,
                      );
                    },
                    child: handle,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}