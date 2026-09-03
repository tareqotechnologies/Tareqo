import 'package:flutter/material.dart';

/// Pílula de status — rótulo com fundo colorido translúcido.
class StatusChip extends StatelessWidget {
 const StatusChip({
 super.key,
 required this.label,
 required this.color,
 this.icon,
 });

 final String label;
 final Color color;
 final IconData? icon;

 @override
 Widget build(BuildContext context) {
 final scheme = Theme.of(context).colorScheme;    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
 color: scheme.brightness == Brightness.dark
 ? color.withValues(alpha: 0.9)
 : color,
 // Chips carregam quantidades/valores/datas — dígitos
 // alinhados em colunas de chips.
 fontFeatures: [FontFeature.tabularFigures()],
 ),
 ),
 ),
 ],
 ),
 );
 }
}
