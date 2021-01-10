
import 'package:flutter/material.dart';

class ProgressDialog extends StatelessWidget {

  String msg;
  ProgressDialog({this.msg});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.yellow,
      child: Container(
        margin: EdgeInsets.all(15),
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(6)
        ),
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Row(
            children: [
              SizedBox(width: 6,),
              CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.black),),
              SizedBox(width: 26,),
              Text(msg, style: TextStyle(
                color: Colors.black,
                fontSize: 10.0
              ),)
            ],
          ),
        ),
      ),
    );
  }
}
