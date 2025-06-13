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
      developer.log(
        name: "AuthenticationServices -> signUpWithEmail",
        "Email can not be empty");
      return showAlertMessage('Email can not be empty');
    }

    if (password.isEmpty || confirmPassword.isEmpty) {
      developer.log(
        name: "AuthenticationServices -> signUpWithEmail",
        "Password can not be empty");
      return showAlertMessage('Password can not be empty');
    }

    try {
      if (password != confirmPassword) {
        developer.log(
          name: "AuthenticationServices -> signUpWithEmail",
          "Password must be the same");
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
        developer.log(
          name: "AuthenticationServices -> signUpWithEmail",
          "User ${currentUser?.email} has been added to collection");
      },
    );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        developer.log(
          name: "AuthenticationServices -> signUpWithEmail -> FirebaseAuthException",
          "$e");
        return showAlertMessage('The account already exists for that email');
      } else if (e.code == 'weak-password') {
        developer.log(
          name: "AuthenticationServices -> signUpWithEmail -> FirebaseAuthException",
          "$e");
        return showAlertMessage('Provided password is too weak');
      }

      return showAlertMessage(e.code);
    } catch (e) {
      developer.log(
        name: "AuthenticationServices -> signUpWithEmail -> exception",
        "$e");
    }
  }

  void signInWithEmail(String email, String password) async {
    if (email.isEmpty) {
      developer.log(
        name: "AuthenticationServices -> signInWithEmail ->",
        "Email can not be empty");
      return showAlertMessage('Email can not be empty');
    }

    if (password.isEmpty) {
      developer.log(
        name: "AuthenticationServices -> signInWithEmail ->",
        "Password can not be empty");
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
        developer.log(
          name: "AuthenticationServices -> signInWithEmail -> FirebaseAuthException",
          "$e");
        return showAlertMessage('Wrong email or password');
      } else if (e.code == 'user-not-found') {
        developer.log(
          name: "AuthenticationServices -> signInWithEmail -> FirebaseAuthException",
          "$e");
        return showAlertMessage('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        developer.log(
          name: "AuthenticationServices -> signInWithEmail -> FirebaseAuthException",
          "$e");
        return showAlertMessage('Wrong password provided for that user.');
      } else if (e.code == 'email-already-in-use') {
        developer.log(
          name: "AuthenticationServices -> signInWithEmail -> FirebaseAuthException",
          "$e");
        return showAlertMessage('The account already exists for that email.');
      }

      return showAlertMessage(e.code);
    } catch (e) {
      developer.log(
        name: "AuthenticationServices -> signInWithEmail -> exception",
        "$e");
    }

    developer.log(
        name: "AuthenticationServices -> signInWithEmail",
        "User has correctly logged in!");
  }

  void signOutCurrentUser() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      developer.log(
        "Current user is null",
        name: "AuthenticationServices -> signOutCurrentUser",
      );
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection("users")
          .doc(currentUser.uid)
          .update({'token': ""});

      developer.log(
        "User Token has been removed",
        name: "AuthenticationServices -> signOutCurrentUser",
      );

      await FirebaseAuth.instance.signOut();

      developer.log(
        "User has been signed out",
        name: "AuthenticationServices -> signOutCurrentUser",
      );

    } catch (e) {
      developer.log(
        "$e",
        name: "AuthenticationServices -> signOutCurrentUser -> exception",
      );
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