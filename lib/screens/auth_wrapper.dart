import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'guest_welcome_screen.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);

    if (user == null) {
      // Show guest welcome screen with option to sign in or continue as guest
      return const GuestWelcomeScreen();
    } else {
      return const HomeScreen();
    }
  }
}