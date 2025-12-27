import 'package:flutter/material.dart';
import 'package:trashgold/screens/LoginScreen.dart';

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
      backgroundColor: Colors.greenAccent,
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
      _buildGetStartedSlide(context),
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

  Widget _buildWelcomeSlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo with subtle emphasis
          Container(
            height: 200,
            width: 200,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.withOpacity(0.06),
            ),
            child: Image.asset(
              'assets/logo.png',
              scale: 2,
              height: 120,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: 48),

          // App name
          const Text(
            'TrashGold',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: Color(0xFF2E7D32), // green tone
            ),
          ),

          const SizedBox(height: 12),

          // Slogan (hook)
          const Text(
            'Turn Waste into Worth',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF424242),
            ),
          ),

          const SizedBox(height: 20),

          // Supporting description
          const Text(
            'Smart recycling made rewarding through AI-powered bins and real-time tracking.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: Color(0xFF616161),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildFeatureSlide(){
    return Text('Welcome Page');
  }
  Widget _buildGetStartedSlide(BuildContext context){
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Get On Board",
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Colors.indigoAccent
          ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 50,),


          ElevatedButton(
            onPressed: (){
              Navigator.push(context,
                 MaterialPageRoute(builder: (context) => const LoginScreen()),);
            },
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: const Text("Let's Log You In"),
          ),

        ],
      ),
    );

  }




}