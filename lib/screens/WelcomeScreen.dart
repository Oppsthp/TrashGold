import 'package:flutter/material.dart';

class WelcomeScreen extends StatefulWidget{
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();

}

class _WelcomeScreenState extends State<WelcomeScreen>{
  final PageController _pageController = PageController();
  int _currentpage=0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildDots(int index){
    return Icon(
      _currentpage == index ? Icons.circle : Icons.cabin_outlined,
      size: 12,
      color: _currentpage == index ? Colors.lightBlue : Colors.grey,
    );
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: Colors.lightBlueAccent,
      body: SafeArea(
        child: Column(
          children: [
Expanded(
  child: PageView(
    controller: _pageController,
    onPageChanged: (index){
      setState(() => _currentpage = index);
    },
    children: [
     _buildWelcomeSlide(),
     _buildFeatureSlide(),
      _buildGetStartedSlide(),
    ],
  ),
),
            Padding(padding: const EdgeInsets.only(bottom: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => _buildDots(index))
                .map((dot)=> Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
                child: dot,
              ))
                .toList(),
            ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeSlide(){
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            child: Image.asset('assets/logo.png', fit: BoxFit.contain),
          ),
          const SizedBox(height: 40),
          const Text(
            'Localite',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E88E5),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            'For when the world goes quiet',
            style: TextStyle(fontSize: 18, color: Color(0xFF424242)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          const Text(
            'Stay connected even if international internet is down.',
            style: TextStyle(fontSize: 16, color: Color(0xFF616161)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }


  Widget _buildFeatureSlide(){
    return Text('Welcome Page');
  }
  Widget _buildGetStartedSlide(){
    return Text('Welcome Page');
  }




}