import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/bio_method.dart';

/// Sistema visual neo-brutalista de FitPulse:
/// bordes de tinta gruesos, sombras duras sin desenfoque, bloques de color
/// plano, texto en mayúsculas y cifras monoespaciadas tipo marcador.
const double kBorder = 2.5;
const double kRadius = 6;

BoxDecoration brutalDecoration({
  Color color = AppColors.card,
  double shadow = 4,
  double radius = kRadius,
}) =>
    BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: AppColors.ink, width: kBorder),
      boxShadow: shadow <= 0
          ? null
          : [BoxShadow(color: AppColors.shadow, offset: Offset(shadow, shadow))],
    );

IconData bioIcon(BioMethod m) =>
    m == BioMethod.face ? Icons.face_retouching_natural_rounded : Icons.fingerprint_rounded;

// ------------------------------------------------------------------ caja
class BrutalBox extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsetsGeometry padding;
  final double shadow;
  const BrutalBox({
    super.key,
    required this.child,
    this.color = AppColors.card,
    this.padding = const EdgeInsets.all(16),
    this.shadow = 4,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: brutalDecoration(color: color, shadow: shadow),
      child: child,
    );
  }
}

// ------------------------------------------------------------------ botón
/// Botón que "se hunde" al presionarlo (la sombra desaparece).
class BrutalButton extends StatefulWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final Color color;
  final Color foreground;
  final bool loading;
  final bool compact;
  const BrutalButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.color = AppColors.lime,
    this.foreground = AppColors.ink,
    this.loading = false,
    this.compact = false,
  });

  @override
  State<BrutalButton> createState() => _BrutalButtonState();
}

class _BrutalButtonState extends State<BrutalButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final shift = _down ? 4.0 : 0.0;
    return Opacity(
      opacity: widget.onPressed == null ? 0.45 : 1,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _down = true) : null,
        onTapUp: enabled ? (_) => setState(() => _down = false) : null,
        onTapCancel: enabled ? () => setState(() => _down = false) : null,
        onTap: enabled
            ? () {
                HapticFeedback.lightImpact();
                widget.onPressed!();
              }
            : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 70),
          width: double.infinity,
          transform: Matrix4.translationValues(shift, shift, 0),
          padding: EdgeInsets.symmetric(vertical: widget.compact ? 12 : 17, horizontal: 14),
          decoration: brutalDecoration(color: widget.color, shadow: 4 - shift),
          child: widget.loading
              ? Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 3, color: widget.foreground),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(widget.icon, color: widget.foreground, size: 22),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        widget.label.toUpperCase(),
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: widget.foreground,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: widget.compact ? 13 : 15,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ campo
class BrutalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscure;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final ValueChanged<String>? onChanged;

  const BrutalField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure = false,
    this.suffix,
    this.keyboardType,
    this.validator,
    this.inputFormatters,
    this.maxLength,
    this.onChanged,
  });

  static OutlineInputBorder _b(Color c, [double w = kBorder]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(kRadius),
        borderSide: BorderSide(color: c, width: w),
      );

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      onChanged: onChanged,
      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 16),
      decoration: InputDecoration(
        labelText: label.toUpperCase(),
        labelStyle: const TextStyle(
            fontWeight: FontWeight.w800, letterSpacing: 1, color: AppColors.inkSoft, fontSize: 13),
        floatingLabelStyle: const TextStyle(
            fontWeight: FontWeight.w900, letterSpacing: 1, color: AppColors.ink),
        prefixIcon: Icon(icon, color: AppColors.ink),
        suffixIcon: suffix,
        filled: true,
        fillColor: AppColors.card,
        counterText: '',
        border: _b(AppColors.ink),
        enabledBorder: _b(AppColors.ink),
        focusedBorder: _b(AppColors.cobalt, 3),
        errorBorder: _b(AppColors.danger),
        focusedErrorBorder: _b(AppColors.danger, 3),
        errorStyle: const TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ------------------------------------------------------------------ avisos
void showBrutalSnack(BuildContext context, String msg, {bool error = false}) {
  final m = ScaffoldMessenger.of(context);
  m.hideCurrentSnackBar();
  m.showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      backgroundColor: Colors.transparent,
      padding: EdgeInsets.zero,
      content: Container(
        padding: const EdgeInsets.all(14),
        decoration: brutalDecoration(color: error ? AppColors.coral : AppColors.lime, shadow: 3),
        child: Row(
          children: [
            Icon(error ? Icons.priority_high_rounded : Icons.check_rounded, color: AppColors.ink),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(color: AppColors.ink, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Diálogo con el mismo lenguaje visual (sin el AlertDialog genérico).
Future<T?> showBrutalDialog<T>({
  required BuildContext context,
  required String title,
  required Widget content,
  required List<Widget> Function(BuildContext ctx) actions,
  IconData? icon,
  Color iconColor = AppColors.lime,
  bool dismissible = true,
}) {
  return showDialog<T>(
    context: context,
    barrierDismissible: dismissible,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (ctx) {
      final acts = actions(ctx);
      return Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: brutalDecoration(color: AppColors.paper, shadow: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: brutalDecoration(color: iconColor, shadow: 0),
                  child: Icon(icon, size: 30, color: AppColors.ink),
                ),
                const SizedBox(height: 14),
              ],
              Text(
                title.toUpperCase(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
              const SizedBox(height: 10),
              DefaultTextStyle.merge(
                style: const TextStyle(color: AppColors.ink, fontSize: 15, height: 1.35),
                child: content,
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  for (var i = 0; i < acts.length; i++) ...[
                    if (i > 0) const SizedBox(width: 10),
                    Expanded(child: acts[i]),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

// ------------------------------------------------------------------ métricas
class MetricBlock extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String unit;
  final Color color;
  const MetricBlock({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.unit = '',
    this.color = AppColors.card,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: brutalDecoration(color: color, shadow: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.ink),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ],
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                      fontFamily: AppTheme.mono, fontSize: 26, fontWeight: FontWeight.w900),
                ),
                if (unit.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  Text(unit, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Cuadrícula de métricas de 2 columnas.
class MetricGrid extends StatelessWidget {
  final List<Widget> children;
  const MetricGrid({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.6,
      children: children,
    );
  }
}

// ------------------------------------------------------------------ etiquetas
class Tag extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;
  final Color foreground;
  const Tag(this.text,
      {super.key, this.color = AppColors.sun, this.icon, this.foreground = AppColors.ink});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: brutalDecoration(color: color, shadow: 0, radius: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: foreground),
            const SizedBox(width: 5),
          ],
          Text(
            text.toUpperCase(),
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1, color: foreground),
          ),
        ],
      ),
    );
  }
}

/// Encabezado numerado: "01 ── DATOS PERSONALES ─────".
class SectionLabel extends StatelessWidget {
  final String number;
  final String text;
  const SectionLabel(this.number, this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            color: AppColors.ink,
            child: Text(number,
                style: const TextStyle(
                    fontFamily: AppTheme.mono,
                    color: AppColors.paper,
                    fontWeight: FontWeight.w900,
                    fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Text(text.toUpperCase(),
              style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 13)),
          const SizedBox(width: 10),
          Expanded(child: Container(height: kBorder, color: AppColors.ink)),
        ],
      ),
    );
  }
}

/// Título grande de pantalla con subrayado de color.
class ScreenTitle extends StatelessWidget {
  final String text;
  final Color underline;
  const ScreenTitle(this.text, {super.key, this.underline = AppColors.lime});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          bottom: 4,
          height: 12,
          child: Container(color: underline),
        ),
        Text(
          text.toUpperCase(),
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w900, height: 1.05, letterSpacing: -0.5),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------ switch
class BrutalSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;
  const BrutalSwitch({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onChanged == null ? null : () => onChanged!(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 60,
        height: 34,
        padding: const EdgeInsets.all(3),
        alignment: value ? Alignment.centerRight : Alignment.centerLeft,
        decoration: brutalDecoration(color: value ? AppColors.lime : AppColors.card, shadow: 0, radius: 4),
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(color: AppColors.ink, borderRadius: BorderRadius.circular(3)),
        ),
      ),
    );
  }
}

/// Opción seleccionable en bloque (sexo, método biométrico...).
class ChoiceBlock extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final Color color;
  const ChoiceBlock({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.enabled = true,
    this.color = AppColors.lime,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: brutalDecoration(
            color: selected ? color : AppColors.card,
            shadow: selected ? 0 : 3,
          ),
          transform: Matrix4.translationValues(selected ? 3 : 0, selected ? 3 : 0, 0),
          child: Column(
            children: [
              Icon(icon, color: AppColors.ink, size: 26),
              const SizedBox(height: 4),
              Text(label.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1)),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------------ fondo
/// Scaffold con fondo de papel punteado (cuadrícula de puntos).
class BrutalScaffold extends StatelessWidget {
  final Widget child;
  final Widget? bottom;
  const BrutalScaffold({super.key, required this.child, this.bottom});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      bottomNavigationBar: bottom,
      body: CustomPaint(
        painter: const DotGridPainter(),
        child: SafeArea(bottom: bottom == null, child: child),
      ),
    );
  }
}

class DotGridPainter extends CustomPainter {
  const DotGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = AppColors.shadow.withValues(alpha: 0.18);
    const gap = 22.0;
    for (double y = gap / 2; y < size.height; y += gap) {
      for (double x = gap / 2; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), 1.1, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Barra superior propia: botón atrás en bloque + título.
class BrutalTopBar extends StatelessWidget {
  final String title;
  final List<Widget> actions;
  final VoidCallback? onBack;
  const BrutalTopBar({super.key, required this.title, this.actions = const [], this.onBack});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          SquareIconButton(
            icon: Icons.arrow_back_rounded,
            onTap: onBack ?? () => Navigator.maybePop(context),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title.toUpperCase(),
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ),
          ...actions,
        ],
      ),
    );
  }
}

class SquareIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  const SquareIconButton(
      {super.key, required this.icon, required this.onTap, this.color = AppColors.card});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: brutalDecoration(color: color, shadow: 3),
        child: Icon(icon, color: AppColors.ink),
      ),
    );
  }
}

/// Barra de progreso con borde de tinta.
class BrutalProgress extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  const BrutalProgress(
      {super.key, required this.value, this.color = AppColors.coral, this.height = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.hardEdge,
      decoration: brutalDecoration(color: AppColors.card, shadow: 0, radius: 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          heightFactor: 1,
          child: Container(color: color),
        ),
      ),
    );
  }
}
