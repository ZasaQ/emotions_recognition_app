import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

import 'package:emotions_recognition_app/pages/camera_page.dart';
import 'package:emotions_recognition_app/services/authentication_handler.dart';
import 'package:emotions_recognition_app/services/firestore_handler.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  AuthenticationHandler authHandler = AuthenticationHandler();
  FirestoreHandler firestoreHandler = FirestoreHandler();

  @override
  void initState() {
    super.initState();

    developer.log(
      name: "HomePage -> initState",
      "Entering Home page.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Home Page")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/user'),
                child: Text("User Page"),
              ),

              ElevatedButton(
                onPressed: () => authHandler.signOutCurrentUser(),
                child: Text("Sign Out"),
              ),

              ElevatedButton(
                onPressed: () => authHandler.removeCurrentUser(),
                child: Text("Delete Account"),
              ),
            ],
          )
        )
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera_alt),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CameraPage()),
          );
        },
      ),
    );
  }
}