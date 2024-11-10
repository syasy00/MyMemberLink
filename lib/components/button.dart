import 'package:flutter/material.dart';

enum ButtonSize { small, medium, large }

enum ButtonState { enabled, loading, disabled }

enum ButtonType { primary, secondary }

class CustomButton extends StatelessWidget {
  const CustomButton({
    Key? key,
    required this.text,
    required this.onPressed,
    this.size = ButtonSize.medium,
    this.type = ButtonType.primary,
    this.state = ButtonState.enabled,
  }) : super(key: key);

  final String text;
  final VoidCallback onPressed;
  final ButtonSize size;
  final ButtonType type;
  final ButtonState state;

  @override
  Widget build(BuildContext context) {
    double padding = _getPadding();
    Color backgroundColor = _getBackgroundColor();
    Color textColor = _getTextColor();

    return SizedBox(
      width: double.infinity, // Sets the button to full width
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          padding: EdgeInsets.symmetric(vertical: padding),
          textStyle: TextStyle(
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30), // Fully rounded button
          ),
        ),
        onPressed: state == ButtonState.enabled ? onPressed : null,
        child: state == ButtonState.loading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                text,
                style: TextStyle(color: textColor),
              ),
      ),
    );
  }

  double _getPadding() {
    switch (size) {
      case ButtonSize.small:
        return 8.0;
      case ButtonSize.medium:
        return 12.0;
      case ButtonSize.large:
        return 16.0;
    }
  }

  double _getFontSize() {
    switch (size) {
      case ButtonSize.small:
        return 14.0;
      case ButtonSize.medium:
        return 16.0;
      case ButtonSize.large:
        return 16.0;
    }
  }

  Color _getBackgroundColor() {
    if (type == ButtonType.primary) {
      return state == ButtonState.disabled ? Colors.grey : Colors.black;
    } else {
      return state == ButtonState.disabled ? Colors.grey[200]! : Colors.purple;
    }
  }

  Color _getTextColor() {
    return type == ButtonType.primary ? Colors.white : Colors.white;
  }
}
