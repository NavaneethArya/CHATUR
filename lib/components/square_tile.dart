import 'package:flutter/material.dart';

class SquareTile extends StatelessWidget {
  const SquareTile({super.key, required this.imagePath, this.onTap});
  final String imagePath;
  final Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Tooltip(
        message: imagePath.contains('google')
            ? 'Sign in with Google'
            : 'Sign in',
        child: Container(
          width: 70,
          height: 70,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white),
          ),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
