import 'package:flutter/material.dart';

class GoogleButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final String text;
  final String iconPath;

  const GoogleButton({
    super.key,
    this.onPressed,
    this.text = 'Sign Up with Google',
    this.iconPath = 'assets/icon/google.png',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          surfaceTintColor: Colors.transparent,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _GoogleMark(iconPath: iconPath),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  final String iconPath;
  const _GoogleMark({required this.iconPath});

  @override
  Widget build(BuildContext context) {
    const double size = 22;
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        iconPath,
        height: size,
        errorBuilder: (context, error, stack) {
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(color: const Color(0xFFBDBDBD)),
            ),
            alignment: Alignment.center,
            child: const Text(
              'G',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A73E8),
              ),
            ),
          );
        },
      ),
    );
  }
}
