import 'package:flutter/material.dart';
import 'package:elegantfaso/utils/boutique/boutique_constants.dart';

class BoutiqueAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final List<Widget>? actions;
  final bool automaticallyImplyLeading;
  final Widget? leading;

  const BoutiqueAppBar({
    Key? key,
    this.title,
    this.actions,
    this.automaticallyImplyLeading = true,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title ?? 'ElegantFaso Boutique',
        style: TextStyle(
          color: BoutiqueColors.primaryText,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      centerTitle: true,
      backgroundColor: BoutiqueColors.primary,
      elevation: 0,
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: leading,
      actions: actions ?? [
        IconButton(
          icon: Icon(Icons.notifications),
          onPressed: () {
            // Naviguer vers les notifications
            Navigator.pushNamed(context, '/boutique/notifications');
          },
        ),
      ],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(15),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}