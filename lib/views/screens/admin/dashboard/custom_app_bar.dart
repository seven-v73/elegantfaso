part of 'admin_dashboard.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget> actions;

  const CustomAppBar({
    required this.title,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: AppColors.primaryDark,
        ),
      ),
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.white,
      iconTheme: IconThemeData(color: AppColors.primaryDark),
      actions: actions,
      shape: Border(
        bottom: BorderSide(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}