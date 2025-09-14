extension StringCasingExtension on String {
  String capitalize() => isNotEmpty
      ? '${this[0].toUpperCase()}${substring(1).toLowerCase()}'
      : '';

  String toTitleCase() => split(' ')
      .map((str) => str.capitalize())
      .join(' ');

  String upper() => toUpperCase();
}
