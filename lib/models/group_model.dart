import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:glitcher/models/user_model.dart';

class Group {
  final String id;
  final String name;
  final String image;
  List<User> users;
  final dynamic timestamp;

  Group({
    this.id,
    this.name,
    this.image,
    this.users,
    this.timestamp,
  });

  factory Group.fromDoc(DocumentSnapshot doc) {
    return Group(
      id: doc.documentID,
      name: doc['name'],
      image: doc['image'],
      users: doc['users'],
      timestamp: doc['timestamp'],
    );
  }
}