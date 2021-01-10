import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:uber_clone/allWidgets/progress_dialog.dart';
import 'package:uber_clone/main.dart';
import 'package:uber_clone/screens/main_screen.dart';
import 'package:uber_clone/screens/register_screen.dart';

class LoginScreen extends StatelessWidget {

  static const String idScreen = "login";

  TextEditingController emailTextEditingController = TextEditingController();
  TextEditingController passwordTextEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              SizedBox(
                height: 35,
              ),
              Image(
                image: AssetImage('assets/images/logo.png'),
                width: 300,
                height: 250,
                alignment: Alignment.center,
              ),
              SizedBox(
                height: 1,
              ),
              Text(
                'Login as a Rider',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24.0, fontFamily: "Brand Bolt"),
              ),
              Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    SizedBox(
                      height: 1,
                    ),
                    TextField(
                      keyboardType: TextInputType.emailAddress,
                      controller: emailTextEditingController,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                    SizedBox(
                      height: 1,
                    ),
                    TextField(
                      obscureText: true,
                      controller: passwordTextEditingController,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(
                          fontSize: 14.0,
                        ),
                        hintStyle: TextStyle(
                          color: Colors.grey,
                          fontSize: 10,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 14.0,
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    RaisedButton(
                      color: Colors.yellow,
                      textColor: Colors.white,
                      child: Container(
                        height: 50.0,
                        child: Center(
                          child: Text('Login', style: TextStyle(fontSize: 18.0,
                            fontFamily: "Brand Bolt",
                            color: Colors.black54,
                          ),),
                        ),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      onPressed: () {
                        if(emailTextEditingController.text.isEmpty) {
                          print('Not valid email');
                          // displayToastMessage('Not valid email', context);
                        } else if(passwordTextEditingController.text.length < 6) {
                          print('Password must be atleast 6 characters');
                          // displayToastMessage('Password must be atleast 6 characters', context);
                        } else {
                          loginUser(context);
                        }
                      },
                    ),
                  ],
                ),
              ),

              FlatButton(onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(
                  builder: (context) => RegistrationScreen(),));
              }, child: Text('Don\'t have an account? Register here')),
            ],
          ),
        ),
      ),
    );
  }

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  void loginUser(BuildContext context) async {

    showDialog(context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProgressDialog(msg: "Authenticating please wait",);
      },
    );

    final User firebaseUser = (
        await _firebaseAuth
            .signInWithEmailAndPassword(
            email: emailTextEditingController.text,
            password: passwordTextEditingController.text
        ).catchError((errorMsg) {
          Navigator.pop(context);
          displayToastMessage("Error ${errorMsg}", context);
        })).user;

    if (firebaseUser != null) { //user created
      userRef.child(firebaseUser.uid).once().then((DataSnapshot snap) {
        if (snap.value != null) {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (context) => MainScreen(),));
          print('Logged In');
        } else {
          Navigator.pop(context);
          _firebaseAuth.signOut();
          print('No record exists');
        }
      });
      displayToastMessage("Account created", context);
    } else {
      // error
      Navigator.pop(context);
      print("Error");
      // displayToastMessage('User has not been created', context);
    }
  }
}


