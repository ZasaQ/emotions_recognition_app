import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:developer' as developer;

import 'package:emotions_recognition_app/firebase_options.dart';
import 'package:emotions_recognition_app/pages/home_page.dart';
import 'package:emotions_recognition_app/pages/login_page.dart';
import 'package:emotions_recognition_app/pages/register_page.dart';
import 'package:emotions_recognition_app/theme_data.dart';
import 'package:emotions_recognition_app/utilities.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<Route<dynamic>> onGeneratedInitialRoutes(String initialRouteName) {
    List<Route<dynamic>> pageStack = [];

    pageStack.add(MaterialPageRoute(builder: (_) => const CheckAuthenticationStatus()));

    return pageStack;
  }

  Route<dynamic>? onGenerateRoute(RouteSettings routeSettings) {
  switch (routeSettings.name) {
    case "/":
      return MaterialPageRoute(builder: (_) => const CheckAuthenticationStatus());
    case "/home":
      return MaterialPageRoute(builder: (_) => const HomePage());
    case "/login":
      return MaterialPageRoute(builder: (_) => const LoginPage());
    case "/register":
      return MaterialPageRoute(builder: (_) => const RegisterPage());
    default:
      return MaterialPageRoute(
        builder: (_) => const Scaffold(body: Center(child: Text('Route not found'))),
      );
  }
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Recognition App',
      navigatorKey: MyApp.navigatorKey,
      onGenerateInitialRoutes: onGeneratedInitialRoutes,
      onGenerateRoute: onGenerateRoute,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      theme: appTheme
    );
  }
}

class CheckAuthenticationStatus extends StatefulWidget {
  const CheckAuthenticationStatus({super.key});

  @override
  State<CheckAuthenticationStatus> createState() => _CheckAuthenticationStatusState();
}

class _CheckAuthenticationStatusState extends State<CheckAuthenticationStatus> {

  @override
  void initState() {
    super.initState();

    FirebaseAuth.instance.authStateChanges().listen((User? user) async {
      if (user != null) {
        MyApp.navigatorKey.currentState!.pushReplacementNamed("/home");

        String? idToken = await user.getIdToken(true);
        appLog("idToken: $idToken");

        developer.log(
          name: "CheckAuthenticationStatus -> initState",
          "Current user is NOT NULL, pushing Home page.");
      } else {
        MyApp.navigatorKey.currentState!.pushReplacementNamed("/login");

        developer.log(
          name: "CheckAuthenticationStatus -> initState",
          "Current user is NULL, pushing Login page.");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}