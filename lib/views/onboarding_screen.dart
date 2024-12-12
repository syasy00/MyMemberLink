import 'package:flutter/material.dart';
import 'package:my_member_link/views/authentication%20/login_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final int _numPages = 4;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView(
            controller: _pageController,
            children: [
              _OnboardingPage(
                backgroundColor: const LinearGradient(
                  colors: [Color(0xFFE8F0FF), Color(0xFFF7FAFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                image: "assets/onboarding.gif",
                title: "Welcome to MyMemberLink",
                description:
                    "Start your journey with us and explore the world of possibilities.",
              ),
              _OnboardingPage(
                backgroundColor: const LinearGradient(
                  colors: [Color(0xFFDDEFFF), Color(0xFFF7FAFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                image: "assets/onboarding2.gif",
                title: "Connect with People",
                description: "Join a community of learners and grow together.",
              ),
              _OnboardingPage(
                backgroundColor: const LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color(0xFFF8FBFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                image: "assets/onboarding3.gif",
                title: "Stay Alert with News",
                description: "Stay updated with the latest news at your fingertips.",
              ),
              _OnboardingPage(
                backgroundColor: const LinearGradient(
                  colors: [Color(0xFFD1EFFF), Color(0xFFF7FAFF)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                image: "assets/onboarding4.gif",
                title: "Achieve Your Goals",
                description:
                    "Set your goals and achieve them with the help of our resources.",
              ),
            ],
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => const LoginScreen()),
              );
            },
            child: const Text(
              "Skip",
              style: TextStyle(
                color: Colors.blueAccent,
                fontWeight: FontWeight.w500,
                fontSize: 16,
              ),
            ),
          ),
          SmoothPageIndicator(
            controller: _pageController,
            count: _numPages,
            effect: const ExpandingDotsEffect(
              activeDotColor: Color(0xFF4A90E2),
              dotColor: Colors.grey,
              dotHeight: 8,
              dotWidth: 8,
              expansionFactor: 4,
              spacing: 4,
            ),
          ),
          GestureDetector(
            onTap: () {
              if (_pageController.page == _numPages - 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              } else {
                _pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF4A90E2),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Row(
                children: const [
                  Text(
                    "Next",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final LinearGradient backgroundColor;
  final String image;
  final String title;
  final String description;

  const _OnboardingPage({
    required this.backgroundColor,
    required this.image,
    required this.title,
    required this.description,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: backgroundColor),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 50),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(image, width: 250, height: 250, fit: BoxFit.contain),
            const SizedBox(height: 30),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              description,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
