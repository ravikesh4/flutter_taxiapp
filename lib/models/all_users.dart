import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class Users {
  String id;
  String email;
  String name;
  String mobile;

  Users({this.id, this.email, this.name, this.mobile});

  Users.fromSnapshot(DataSnapshot dataSnapshot) {
    id = dataSnapshot.key;
    email = dataSnapshot.value["email"];
    name = dataSnapshot.value["name"];
    mobile = dataSnapshot.value["mobile"];
  }
}