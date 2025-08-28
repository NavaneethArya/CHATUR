// import 'package:flutter/material.dart';
// import 'package:liquid_swipe/liquid_swipe.dart';
// import 'package:lite_rolling_switch/lite_rolling_switch.dart'; // Import the new package
//
// import 'OnboardingScreen.dart';
// // Import your actual OnboardingScreen from its file
// // For example: import 'package:your_app_name/onboarding_screen.dart';
// // Note: You must replace the line above with the correct path to your OnboardingScreen widget.
//
// class SplashScreen extends StatefulWidget {
//   const SplashScreen({super.key});
//
//   @override
//   _SplashScreenState createState() => _SplashScreenState();
// }
//
// class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
//   late AnimationController _animationController;
//   final LiquidController _liquidController = LiquidController();
//
//   // A minimum duration for the splash screen.
//   final Duration _minSplashDuration = const Duration(seconds: 3);
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialize the animation controller for the swipe arrow with a fluid curve.
//     _animationController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1500),
//     )..repeat(reverse: true); // This will make the animation repeat back and forth smoothly.
//   }
//
//   @override
//   void dispose() {
//     // Dispose of all controllers to free up resources.
//     _animationController.dispose();
//     // LiquidController does not need to be disposed.
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     // We are now using LiquidSwipe to handle the page navigation and animation.
//     final pages = [
//       Scaffold(
//         body: Stack(
//           fit: StackFit.expand,
//           children: <Widget>[
//             // Use Image.asset to display the GIF.
//             Image.asset(
//               'assets/Videos/background_V1.gif',
//               fit: BoxFit.contain,
//               height: MediaQuery.of(context).size.height,
//               width: MediaQuery.of(context).size.width,
//             ),
//             // A semi-transparent overlay to make the text more readable.
//             Container(
//               color: Colors.black.withOpacity(0),
//             ),
//             // The content on top of the video.
//             Container(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.end,
//                 crossAxisAlignment: CrossAxisAlignment.center,
//                 children: <Widget>[
//                   const SizedBox(height: 20), // Added spacing
//                   Container(
//                     padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                     decoration: BoxDecoration(
//                       color: Colors.white.withOpacity(0.7),
//                       borderRadius: BorderRadius.circular(50),
//                     ),
//                     child: const Text(
//                       'Welcome!',
//                       style: TextStyle(
//                         fontSize: 56, // Made text bigger
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black,
//                         fontFamily: 'Roboto',
//                       ),
//                     ),
//                   ),
//                   const SizedBox(height: 10),
//                   // This is the new animated swipe UI
//                   AnimatedBuilder(
//                     animation: _animationController,
//                     builder: (BuildContext context, Widget? child) {
//                       // Apply a CurvedAnimation for a fluid, non-linear effect.
//                       final curvedValue = Curves.easeInOutSine.transform(_animationController.value);
//
//                       return Container(
//                         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                         decoration: BoxDecoration(
//                           color: Colors.black.withOpacity(0.7),
//                           borderRadius: BorderRadius.circular(30),
//                         ),
//                         child: Row(
//                           mainAxisSize: MainAxisSize.min, // Wrap content tightly
//                           mainAxisAlignment: MainAxisAlignment.center, // Align to the start for a left-pointing arrow
//                           children: [
//                             // Updated the icon and transform to make it point and move to the left
//                             Transform.translate(
//                               offset: Offset(-20 * curvedValue, 0),
//                               child: Opacity(
//                                 opacity: 1 - curvedValue,
//                                 child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 28),
//                               ),
//                             ),
//                             const SizedBox(width: 15),
//                              Text(
//                               'Swipe to Begin',
//                               style: TextStyle(
//                                 fontSize: 22,
//                                 color: Colors.white,
//                                 fontWeight: FontWeight.bold,
//                                 fontFamily:'Roboto',
//                               ),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                   const SizedBox(height: 100),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//       Container(
//         color: Colors.black,
//       ),
//       // This is the transparent placeholder for the swipe effect
//       OnboardingScreen(),
//     ];
//
//     return LiquidSwipe(
//       pages: pages,
//       liquidController: _liquidController,
//       enableLoop: false,
//       onPageChangeCallback: (index) {
//         // When the user has swiped to the second page (index 1), navigate to the OnboardingScreen
//         // and add it to the navigation stack, allowing a swipe back.
//         if (index == 1) {
//           Navigator.of(context).push(
//             MaterialPageRoute(
//               builder: (context) => OnboardingScreen(),
//             ),
//           );
//         }
//       },
//     );
//   }
// }
//
import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'OnboardingScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}
class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  final LiquidController _liquidController = LiquidController();

  final Duration _minSplashDuration = const Duration(seconds: 3);

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true); // This will make the animation repeat back and forth smoothly.
  }

  @override
  void dispose() {

    _animationController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    final pages = [
      Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Image.asset(
              'assets/Videos/background_V1.gif',
              fit: BoxFit.contain,
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
            ),
            Container(
              color: Colors.black.withOpacity(0),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 5.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[

                  const SizedBox(height: 50),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      // Using a LinearGradient for a smoother, more dynamic look
                      gradient: LinearGradient(
                        colors: [
                          Colors.blueAccent.withOpacity(0.7),
                          Colors.purpleAccent.withOpacity(0.7)
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'Welcome!',
                      style: const TextStyle(
                        fontSize: 56, // Made text bigger
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        fontFamily: 'Lobster',
                      ),
                    ),
                  ),

                  const SizedBox(height: 500),
                  // This is the new animated swipe UI
                  AnimatedBuilder(
                    animation: _animationController,
                    builder: (BuildContext context, Widget? child) {

                      final curvedValue = Curves.easeInOutSine.transform(_animationController.value);

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min, // Wrap content tightly
                          mainAxisAlignment: MainAxisAlignment.center, // Align to the start for a left-pointing arrow
                          children: [

                            Transform.translate(
                              offset: Offset(-20 * curvedValue, 0),
                              child: Opacity(
                                opacity: 1 - curvedValue,
                                child: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white, size: 28),
                              ),
                            ),
                            const SizedBox(width: 15),

                            Text(
                              'Swipe to Begin',
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontFamily:'Lobster',
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      Container(
        color: Colors.black,
      ),

      OnboardingScreen(),
    ];

    return LiquidSwipe(
      pages: pages,
      liquidController: _liquidController,
      enableLoop: false,
      onPageChangeCallback: (index) {

        if (index == 1) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => OnboardingScreen(),
            ),
          );
        }
      },
    );
  }
}

