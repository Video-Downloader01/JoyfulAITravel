import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
      runApp(const JoyfulTravelApp());
      }

      class JoyfulTravelApp extends StatelessWidget {
        const JoyfulTravelApp({super.key});
          @override
            Widget build(BuildContext context) {
                return MaterialApp(
                      title: 'Joyful AI Travel',
                            theme: ThemeData(
                                    brightness: Brightness.dark,
                                            scaffoldBackgroundColor: const Color(0xFF121212),
                                                    primaryColor: const Color(0xFF556B2F),
                                                            textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
                                                                  ),
                                                                        debugShowCheckedModeBanner: false,
                                                                              home: const AuthWrapper(),
                                                                                  );
                                                                                    }
                                                                                    }

                                                                                    // ... (Baki ka pura code jo pehle message mein tha)
                                                                                    