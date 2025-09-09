import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:developer' as developer;

import 'package:emotions_recognition_app/main.dart';
import 'package:emotions_recognition_app/utilities.dart';

class AuthenticationHandler {
  void signUpWithEmail(String email, String password, String confirmPassword) async {
    if (email.isEmpty) {
      appLog("Email can not be empty");
      return showAlertMessage('Email can not be empty');
    }

    if (password.isEmpty || confirmPassword.isEmpty) {
      appLog("Password can not be empty");
      return showAlertMessage('Password can not be empty');
    }

    try {
      if (password != confirmPassword) {
        appLog("Password must be the same");
        return showAlertMessage("Password must be the same");
      }

      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);

      User? currentUser = FirebaseAuth.instance.currentUser;

      await FirebaseMessaging.instance.getToken().then(
      (token) async {
        await utilsUsersCollection.doc(FirebaseAuth.instance.currentUser!.uid).set(
          {
            'uid': currentUser?.uid,
            'email': currentUser?.email,
            'isAdmin': false,
            'token': token,
            'avatarImage': "",
          },
        );
        appLog("User ${currentUser?.email} has been added to collection");
      },
    );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        appLog("$e");
        return showAlertMessage('The account already exists for that email');
      } else if (e.code == 'weak-password') {
        appLog("$e");
        return showAlertMessage('Provided password is too weak');
      }

      return showAlertMessage(e.code);
    } catch (e) {
      appLog("Exception: $e");
    }
  }

  void signInWithEmail(String email, String password) async {
    if (email.isEmpty) {
      appLog("Email can not be empty");
      return showAlertMessage('Email can not be empty');
    }

    if (password.isEmpty) {
      appLog("Password can not be empty");
      return showAlertMessage('Password can not be empty');
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

      FirebaseMessaging.instance.getToken().then(
        (token) async {
          await utilsUsersCollection.doc(FirebaseAuth.instance.currentUser!.uid).update(
            {
              'token': token,
            },
          );
        },
      );

    } on FirebaseAuthException catch (e) {
      if (e.code == 'invalid-credential') {
        appLog("$e");
        return showAlertMessage('Wrong email or password');
      } else if (e.code == 'user-not-found') {
        appLog("$e");
        return showAlertMessage('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        appLog("$e");
        return showAlertMessage('Wrong password provided for that user.');
      } else if (e.code == 'email-already-in-use') {
        appLog("$e");
        return showAlertMessage('The account already exists for that email.');
      }

      return showAlertMessage(e.code);
    } catch (e) {
      appLog("$e");
    }

    appLog("User has correctly logged in!");
  }

  void signOutCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      appLog("Current user is null");
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .update({'token': ""});

      appLog("User Token has been removed");

      await FirebaseAuth.instance.signOut();

      appLog("User has been signed out");

    } catch (e) {
      appLog("$e");
    }
  }

  void removeCurrentUser() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      String uid = currentUser!.uid;

      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable('deleteFirebaseAuthUser');
      await callable.call({'uid' : uid});

      await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .delete();

      await FirebaseAuth.instance.signOut();
    } catch(e) {
      appLog("Exception: $e");
    }
  }

}