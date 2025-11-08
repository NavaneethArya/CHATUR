// import 'dart:async';
// import 'package:flutter/material.dart';

// class OnboardingScreen extends StatefulWidget {
//   const OnboardingScreen({super.key});

//   @override
//   // ignore: library_private_types_in_public_api
//   _OnboardingScreenState createState() => _OnboardingScreenState();
// }

// class _OnboardingScreenState extends State<OnboardingScreen> {
//   final PageController _controller = PageController();
//   int _currentPage = 0;
//   late Timer _timer;

//   final List<Map<String, String>> onboardingData = [
//     {
//       "image": "assets/images/onboarding1.jpg",
//       "title": "Discover Schemes Easily",
//       "subtitle": "Find government schemes in your language with AI guidance."
//     },
//     {
//       "image": "assets/images/onboarding2.jpg",
//       "title": "Connect with Skilled People",
//       "subtitle": "Find and offer services within your own village."
//     },
//     {
//       "image": "assets/images/onboarding3.jpg",
//       "title": "Stay Updated Locally",
//       "subtitle": "Get alerts for camps, welfare drives, and local events."
//     },
//   ];

//   @override
//   void initState() {
//     super.initState();
//     _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
//       if (_currentPage < onboardingData.length - 1) {
//         _currentPage++;
//       } else {
//         _currentPage = 0;
//       }
//       _controller.animateToPage(
//         _currentPage,
//         duration: const Duration(milliseconds: 400),
//         curve: Curves.easeInOut,
//       );
//     });
//   }

//   @override
//   void dispose() {
//     _timer.cancel();
//     _controller.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           PageView.builder(
//             controller: _controller,
//             itemCount: onboardingData.length,
//             onPageChanged: (index) => setState(() => _currentPage = index),
//             itemBuilder: (context, index) {
//               return Padding(
//                 padding: const EdgeInsets.all(20.0),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Image.asset(onboardingData[index]["image"]!, height: 300),
//                     const SizedBox(height: 30),
//                     Text(
//                       onboardingData[index]["title"]!,
//                       style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       onboardingData[index]["subtitle"]!,
//                       textAlign: TextAlign.center,
//                       style: const TextStyle(fontSize: 16, color: Colors.grey),
//                     ),
//                   ],
//                 ),
//               );
//             },
//           ),
//           Positioned(
//             bottom: 100,
//             left: 0,
//             right: 0,
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: List.generate(onboardingData.length, (index) {
//                 return AnimatedContainer(
//                   duration: const Duration(milliseconds: 300),
//                   margin: const EdgeInsets.symmetric(horizontal: 5),
//                   height: 8,
//                   width: _currentPage == index ? 24 : 8,
//                   decoration: BoxDecoration(
//                     color: _currentPage == index ? Colors.orange : Colors.grey,
//                     borderRadius: BorderRadius.circular(5),
//                   ),
//                 );
//               }),
//             ),
//           ),
//           if (_currentPage == onboardingData.length - 1)
//             Positioned(
//               bottom: 30,
//               left: 40,
//               right: 40,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.pushReplacementNamed(context, '/Elogin');
//                 },
//                 style: ElevatedButton.styleFrom(
//                   padding: const EdgeInsets.symmetric(vertical: 15),
//                   backgroundColor: Colors.orange,
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(30),
//                   ),
//                 ),
//                 child: Text("Get Started"),
//               ),
//             )
//         ],
//       ),
//     );
//   }
// }

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    // --- Choose ONE of these two options ---
    // 1️⃣ Local asset video (recommended for packaged intro)
    _controller = VideoPlayerController.asset("assets/videos/intro.mp4");

    // 2️⃣ Or use a network video
    // _controller = VideoPlayerController.networkUrl(
    //   Uri.parse("https://yourvideoURL.com/intro.mp4"),
    // );

    _controller.initialize().then((_) {
      _controller.play();
      _controller.setLooping(false);
      setState(() {});
    });

    // --- Auto navigate after 10 seconds ---
    Future.delayed(const Duration(seconds: 10), () {
      Navigator.pushReplacementNamed(context, '/Elogin');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child:
            _controller.value.isInitialized
                ? SizedBox.expand(
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: _controller.value.size.width,
                      height: _controller.value.size.height,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                )
                : const CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}
