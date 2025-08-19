import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

enum ButtonVariant { primary, secondary, outline, ghost }
enum ButtonSize { small, medium, large }

class MyButton extends StatefulWidget {
  final VoidCallback? onTap;
  final String text;
  final ButtonVariant variant;
  final ButtonSize size;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;

  const MyButton({
    super.key,
    required this.onTap,
    required this.text,
    this.variant = ButtonVariant.primary,
    this.size = ButtonSize.medium,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
  });

  @override
  State<MyButton> createState() => _MyButtonState();
}

class _MyButtonState extends State<MyButton> with TickerProviderStateMixin {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Definir cores baseadas na variante
    Color backgroundColor;
    Color textColor;
    Color borderColor = Colors.transparent;

    switch (widget.variant) {
      case ButtonVariant.primary:
        backgroundColor = widget.onTap != null ? AppTheme.primaryBlue : Colors.grey.shade400;
        textColor = AppTheme.textLight;
        break;
      case ButtonVariant.secondary:
        backgroundColor = widget.onTap != null ? AppTheme.secondary : Colors.grey.shade400;
        textColor = AppTheme.textLight;
        break;
      case ButtonVariant.outline:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.primaryBlue;
        borderColor = AppTheme.primaryBlue;
        break;
      case ButtonVariant.ghost:
        backgroundColor = Colors.transparent;
        textColor = AppTheme.primaryBlue;
        break;
    }

    // Definir padding baseado no tamanho
    EdgeInsets padding;
    double fontSize;
    switch (widget.size) {
      case ButtonSize.small:
        padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
        fontSize = 14;
        break;
      case ButtonSize.medium:
        padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 16);
        fontSize = 16;
        break;
      case ButtonSize.large:
        padding = const EdgeInsets.symmetric(horizontal: 32, vertical: 20);
        fontSize = 18;
        break;
    }

    return Container(
      width: widget.fullWidth ? double.infinity : null,
      margin: widget.fullWidth ? const EdgeInsets.symmetric(horizontal: 24) : null,
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onTap,
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: AppTheme.borderRadius,
              border: borderColor != Colors.transparent 
                ? Border.all(color: borderColor, width: 2) 
                : null,
              boxShadow: widget.variant == ButtonVariant.primary && widget.onTap != null
                ? [
                    BoxShadow(
                      color: AppTheme.primaryBlue.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
              gradient: widget.variant == ButtonVariant.primary && widget.onTap != null
                ? AppTheme.primaryGradient
                : null,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isLoading) ...[
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                ] else if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    color: textColor,
                    size: fontSize + 2,
                  ),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.isLoading ? 'Carregando...' : widget.text,
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontWeight: FontWeight.w600,
                    fontSize: fontSize,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0);
  }
}
