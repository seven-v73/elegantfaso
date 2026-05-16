part of 'admin_dashboard.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;

  const CustomAppBar({super.key, required this.title, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w900,
          color: AppColors.primaryDark,
          letterSpacing: 0,
        ),
      ),
      centerTitle: false,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      backgroundColor: ModernColors.canvas,
      iconTheme: const IconThemeData(color: AppColors.primaryDark),
      actions: actions,
      shape: const Border(
        bottom: BorderSide(color: ModernColors.line, width: 1),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
