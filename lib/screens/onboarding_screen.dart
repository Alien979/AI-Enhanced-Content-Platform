import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Welcome to AI Book Writing',
      description: 'Create, collaborate, and publish your books with the power of AI.',
      image: 'assets/images/onboarding1.png',
    ),
    OnboardingPage(
      title: 'Write with AI Assistance',
      description: 'Get intelligent suggestions and overcome writer\'s block.',
      image: 'assets/images/onboarding2.png',
    ),
    OnboardingPage(
      title: 'Publish and Share',
      description: 'Share your creations with the world in our public library.',
      image: 'assets/images/onboarding3.png',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (int page) {
              setState(() {
                _currentPage = page;
              });
            },
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: _buildPageIndicator(),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  child: Text(_currentPage == _pages.length - 1 ? 'Get Started' : 'Next'),
                  onPressed: () {
                    if (_currentPage == _pages.length - 1) {
                      _completeOnboarding();
                    } else {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeIn,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(page.image, height: 300),
          const SizedBox(height: 40),
          Text(page.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text(page.description, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  List<Widget> _buildPageIndicator() {
    List<Widget> indicators = [];
    for (int i = 0; i < _pages.length; i++) {
      indicators.add(
        Container(
          width: 10,
          height: 10,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == _currentPage ? Theme.of(context).primaryColor : Colors.grey,
          ),
        ),
      );
    }
    return indicators;
  }

  void _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    Navigator.pushReplacementNamed(context, '/');
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;

  OnboardingPage({required this.title, required this.description, required this.image});
}