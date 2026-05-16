class TalentPortfolioItem {
  const TalentPortfolioItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.type,
    this.price = 0,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String type;
  final double price;
}
