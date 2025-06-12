import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:stack_trace/stack_trace.dart';
import 'dart:developer' as developer;

import 'package:emotions_recognition_app/main.dart';
import 'package:emotions_recognition_app/theme_data.dart';


CollectionReference utilsUsersCollection = FirebaseFirestore.instance.collection("users");

void showAlertMessage(String message) {
  BuildContext context = MyApp.navigatorKey.currentState!.overlay!.context;
  showDialog<void>(
    context: context,
    barrierDismissible: true,
    builder: (BuildContext dialogContext) {
      return AlertDialog(
        backgroundColor: themeMainBackgroundColor,
        title: Text(
          message,
          style: const TextStyle(color: Colors.black),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.center,
      );
    },
  );
}

void appLog(String message, {String? tag}) {
  final frames = Trace.current(1).frames;

  if (frames.isEmpty) {
    developer.log(message, name: tag ?? "Unknown");
    return;
  }

  final frame = frames.first;
  final member = frame.member ?? 'UnknownMember';

  final cleanMember = member.contains('.<')
      ? member.substring(0, member.indexOf('.<'))
      : member;

  final fileName = frame.uri.pathSegments.isNotEmpty
      ? frame.uri.pathSegments.last
      : frame.library;

  final location = "$fileName → $cleanMember";

  developer.log(
    message,
    name: tag ?? location,
  );
}

void showAlertMessageWithTimer(final String message, int durationTime) {
  Timer timer = Timer(Duration(seconds: durationTime), () {
    Navigator.of(MyApp.navigatorKey.currentContext!).pop();
  });

  showDialog<String>(context: MyApp.navigatorKey.currentContext!, builder: (context) => Center(
    child: AlertDialog(
      backgroundColor: themeMainBackgroundColor,
      title: Text(
        message,
        style: const TextStyle(color: Colors.black),
        textAlign: TextAlign.center
      )
    )
  )).then((value) => {
    if (durationTime > 0) {
      timer.cancel()
    }
  });
}
