import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;

import 'package:emotions_recognition_app/utilities.dart';


class FirestoreHandler {
  Future<bool> addUserToCollection({required UserCredential userCredential}) async {
    bool userCreated = false;
    
    await FirebaseMessaging.instance.getToken().then(
      (token) async {
        await utilsUsersCollection.doc(userCredential.user?.uid).set(
          {
            'uid': userCredential.user?.uid,
            'email': userCredential.user?.email,
            'isAdmin': false,
            'token': token,
            'avatarImage': "",
          },
        ).then((value) => userCreated = true);
        developer.log(
          name: "AuthenticationServices -> addUserToCollection",
          "User ${userCredential.user?.email} has been added to collection");
      },
    );

    return userCreated;
  }

  Future<void> deleteUserFromCollection({required String uid}) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deleteFirebaseAuthUser');
      await callable.call({'uid' : uid});

      await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .delete();

      developer.log(
        name: "FirestoreHandler -> deleteUserFromCollection",
        "User has been deleted correctly");
    } on FirebaseAuthException catch (e) {
      developer.log(
        name: "AuthenticationServices -> deleteUserFromCollection -> FirebaseAuthException",
        "$e");
    }
  }

}