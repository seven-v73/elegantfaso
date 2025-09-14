String formatTimeAgo(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inSeconds < 60) {
    return 'à l\'instant';
  } else if (difference.inMinutes < 60) {
    return 'il y a ${difference.inMinutes} min';
  } else if (difference.inHours < 24) {
    return 'il y a ${difference.inHours} h';
  } else if (difference.inDays < 7) {
    return 'il y a ${difference.inDays} j';
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return 'il y a $weeks sem';
  } else if (difference.inDays < 365) {
    final months = (difference.inDays / 30).floor();
    return 'il y a $months mois';
  } else {
    final years = (difference.inDays / 365).floor();
    return 'il y a $years ans';
  }
}