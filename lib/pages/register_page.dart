import 'package:flutter/material.dart';
import 'package:emotions_recognition_app/services/authentication_handler.dart';
import 'dart:developer' as developer;

import 'package:emotions_recognition_app/utilities.dart';


class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  AuthenticationHandler authHandler = AuthenticationHandler();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();

    appLog("Entering Register page.");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Register"),
        actions: [
            TextButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
              child: const Text(
                "Login",
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
              // Name field
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: "Email"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter your name" : null,
              ),

              SizedBox(height: 12),

              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(labelText: "Password"),
                obscureText: true,
              ),

              SizedBox(height: 12),

              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(labelText: "Confirm password"),
                obscureText: true,
                validator: (value) => value!.length < 6
                    ? "Password must be at least 6 characters"
                    : null,
              ),

              SizedBox(height: 20),

              ElevatedButton(
                onPressed: () => authHandler.signUpWithEmail(_emailController.text, _passwordController.text, _confirmPasswordController.text),
                child: Text("Register"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}