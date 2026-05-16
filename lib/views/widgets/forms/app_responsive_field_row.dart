import 'package:flutter/material.dart';

class AppResponsiveFieldRow extends StatelessWidget {
  const AppResponsiveFieldRow({
    super.key,
    required this.children,
    this.breakpoint = 360,
    this.spacing = 12,
  });

  final List<Widget> children;
  final double breakpoint;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            children: [
              for (var index = 0; index < children.length; index++) ...[
                if (index > 0) SizedBox(height: spacing),
                children[index],
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var index = 0; index < children.length; index++) ...[
              if (index > 0) SizedBox(width: spacing),
              Expanded(child: children[index]),
            ],
          ],
        );
      },
    );
  }
}
