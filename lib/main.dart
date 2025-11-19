import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'firebase_options.dart';
import 'models/user.dart';
import 'services/auth_service.dart';
import 'services/user_service.dart';
import 'services/usage_service.dart';
import 'screens/auth_wrapper.dart';
import 'screens/signup_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/vip_screen.dart';
import 'screens/subscription_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const RecipeTadkaApp());
}

class RecipeTadkaApp extends StatelessWidget {
  const RecipeTadkaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(),
        ),
        Provider<UserService>(
          create: (_) => UserService(),
        ),
        Provider<UsageService>(
          create: (_) => UsageService(),
        ),
        StreamProvider<User?>(
          create: (context) => FirebaseAuth.instance.authStateChanges(),
          initialData: null,
        ),
        StreamProvider<UserModel?>(
          create: (context) {
            final userService = context.read<UserService>();
            return FirebaseAuth.instance.authStateChanges().asyncExpand((user) {
              if (user == null) {
                return Stream.value(UserModel.guest());
              }
              return userService
                  .getUser(user.uid)
                  .map((model) => model ??
                      UserModel(
                        uid: user.uid,
                        email: user.email ?? '',
                        role: 'regular',
                      ));
            });
          },
          initialData: UserModel.guest(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'RECIPE TADKA',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
          textTheme: GoogleFonts.poppinsTextTheme(),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const AuthWrapper(),
          '/home': (_) => const HomeScreen(),
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignUpScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/admin': (_) => const AdminScreen(),
          '/vip': (_) => const VipScreen(),
          '/subscription': (_) => const SubscriptionScreen(),
        },
      ),
    );
  }
}