import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GlassTextField extends StatefulWidget {
  final String hint;
  final IconData? icon;
  final bool isPassword;
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final void Function()? changeSuffixIcon;
  final String? initialValue;

  const GlassTextField({
    super.key,
    required this.hint,
    this.icon,
    this.isPassword = false,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.changeSuffixIcon,
    this.initialValue,
  });

  @override
  State<GlassTextField> createState() => _GlassTextFieldState();
}

class _GlassTextFieldState extends State<GlassTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      setState(() {
        _isFocused = _focusNode.hasFocus;
      });
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const neonCyan = Color(0xFF00C2FF);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _isFocused
                  ? [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.1),
                    ]
                  : [
                      Colors.white.withOpacity(0.08),
                      Colors.white.withOpacity(0.02),
                    ],
            ),
            border: Border.all(
              color: _isFocused
                  ? neonCyan.withOpacity(0.6)
                  : Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: _isFocused
                ? [
                    BoxShadow(
                      color: neonCyan.withOpacity(0.15),
                      blurRadius: 12,
                      spreadRadius: -2,
                    ),
                  ]
                : [],
          ),
          child: TextFormField(
            focusNode: _focusNode,
            controller: widget.controller,
            initialValue: widget.initialValue,
            obscureText: widget.isPassword,
            keyboardType: widget.keyboardType,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: neonCyan,
            decoration: InputDecoration(
              prefixIcon: widget.icon == null
                  ? null
                  : Icon(
                      widget.icon,

                      color: _isFocused
                          ? neonCyan
                          : Colors.white.withOpacity(0.4),
                      size: 20,
                    ),
              suffixIcon: widget.changeSuffixIcon != null
                  ? GestureDetector(
                      onTap: widget.changeSuffixIcon,
                      child: Icon(
                        widget.isPassword
                            ? CupertinoIcons.eye_slash
                            : CupertinoIcons.eye,
                        color: _isFocused
                            ? neonCyan
                            : Colors.white.withOpacity(0.4),
                        size: 20,
                      ),
                    )
                  : null,
              hintText: widget.hint,
              hintStyle: GoogleFonts.poppins(
                color: Colors.white.withOpacity(0.3),
                fontSize: 14,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
