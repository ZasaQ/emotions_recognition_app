import 'package:flutter/material.dart';
import 'dart:developer' as developer;

import 'package:emotions_recognition_app/utilities.dart';
import 'package:emotions_recognition_app/services/authentication_handler.dart';


class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  AuthenticationHandler authHandler = AuthenticationHandler();
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    appLog("Entering Login page.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Login Page"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/register'),
            child: const Text(
              "Register",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter your email" : null,
              ),

              SizedBox(height: 12),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
              ),

              SizedBox(height: 12),

              ElevatedButton(
                onPressed: () => authHandler.signInWithEmail(_emailController.text, _passwordController.text),
                child: Text("Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}