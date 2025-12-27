import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:trashgold/screens/WelcomeScreen.dart';

void main () async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
   return MaterialApp(
     debugShowCheckedModeBanner: false,
     title: 'Trash Gold',
     theme: ThemeData(
       primaryColor:  Colors.red,
       scaffoldBackgroundColor: Colors.greenAccent,
     ),
home: const WelcomeScreen(),

   );

  }

}