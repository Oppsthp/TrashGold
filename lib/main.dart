import 'package:flutter/material.dart';
import 'package:trashgold/screens/WelcomeScreen.dart';

void main(){
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
       scaffoldBackgroundColor: Colors.lightBlue,
     ),
home: const WelcomeScreen(),

   );

  }

}