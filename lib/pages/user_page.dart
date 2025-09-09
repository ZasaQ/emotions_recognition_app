import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

import 'package:emotions_recognition_app/utilities.dart';


class UserPage extends StatefulWidget {
  const UserPage({super.key});

  @override
  State<UserPage> createState() => _UserPageState();
}

class _UserPageState extends State<UserPage> {
  late String _userEmail;

  @override
  void initState() {
    super.initState();

    appLog("Entering User page.");

    _userEmail = FirebaseAuth.instance.currentUser!.email!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("User Page")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Center(child: Text('Logged in as ${_userEmail}')),
          ],
        )
      ),
    );
  }
}