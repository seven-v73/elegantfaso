import 'package:flutter/material.dart';

import '../../../../../design/modern_design_system.dart';
import '../../../../../models/salon/salon_context.dart';

class SalonScopeSwitcher extends StatelessWidget {
  const SalonScopeSwitcher({
    super.key,
    required this.value,
    required this.onChanged,
    this.compact = false,
  });

  final SalonDiscoveryScope value;
  final ValueChanged<SalonDiscoveryScope> onChanged;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: ModernColors.canvas,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: ModernColors.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children:
            SalonDiscoveryScope.values.map((scope) {
              final selected = scope == value;
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(scope),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 8 : 10,
                      vertical: compact ? 8 : 9,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected ? ModernColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      compact ? scope.label : scope.fullLabel,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? Colors.white : ModernColors.inkSoft,
                        fontSize: compact ? 11 : 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }
}
