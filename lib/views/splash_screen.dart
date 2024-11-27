import 'package:flutter/material.dart';
import 'package:my_member_link/views/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _logoPosition = 0.0;

  @override
  void initState() {
    super.initState();

    // Trigger logo animation
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _logoPosition = -100;
      });
    });

    // Navigate to onboarding screen after delay
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated soft gradient background
          AnimatedGradientBackground(),
          // Foreground content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated logo
              AnimatedAlign(
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutQuad,
                alignment: Alignment(0, _logoPosition),
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 800),
                  opacity: 1.0,
                  child: Image.asset(
                    "assets/logo.png",
                    width: 100,
                    height: 100,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // App name
              const Text(
                "MyMemberLink",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Nunito',
                  color: Color(0xFF274472), // Soft blue text
                ),
              ),
              const SizedBox(height: 10),
              // Tagline
              const Text(
                "Connecting Your Community",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w300,
                  fontStyle: FontStyle.italic,
                  color: Color(0xFF4A6476), // Subtle grayish-blue text
                ),
              ),
              const SizedBox(height: 40),
              // Subtle dots loader animation
              FadeAndGrowDotsLoader(),
            ],
          ),
        ],
      ),
    );
  }
}

class AnimatedGradientBackground extends StatefulWidget {
  @override
  _AnimatedGradientBackgroundState createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _color1;
  late Animation<Color?> _color2;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _color1 = ColorTween(
      begin: Colors.blue.shade50,
      end: Colors.blue.shade200,
    ).animate(_controller);

    _color2 = ColorTween(
      begin: Colors.teal.shade50,
      end: Colors.teal.shade200,
    ).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [_color1.value!, _color2.value!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      },
    );
  }
}

class FadeAndGrowDotsLoader extends StatefulWidget {
  @override
  _FadeAndGrowDotsLoaderState createState() => _FadeAndGrowDotsLoaderState();
}

class _FadeAndGrowDotsLoaderState extends State<FadeAndGrowDotsLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _controller.value,
              child: Transform.scale(
                scale: _controller.value,
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF274472), // Soft blue dot color
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
