part of 'chat_screen.dart';

// Écran de détail produit
class ProductDetailScreen extends StatefulWidget {
  final Produit produit;
  final VoidCallback? onOrder;

  const ProductDetailScreen({super.key, required this.produit, this.onOrder});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final SalonAnalyticsService _analyticsService = SalonAnalyticsService();

  @override
  void initState() {
    super.initState();
    _analyticsService.trackListingView(
      itemId: widget.produit.id,
      itemType: 'product',
      ownerId: widget.produit.boutiqueId ?? '',
      title: widget.produit.nom,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.produit.nom),
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: CachedNetworkImage(
                imageUrl: widget.produit.imageUrl,
                height: 300,
                fit: BoxFit.cover,
                placeholder:
                    (context, url) => Container(
                      color: Colors.grey[200],
                      height: 300,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                errorWidget:
                    (context, url, error) => Container(
                      color: Colors.grey[200],
                      height: 300,
                      child: const Icon(Icons.error, size: 50),
                    ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.produit.nom,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.produit.prix.toStringAsFixed(2)} €',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              widget.produit.description,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.inventory, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Disponible: ${widget.produit.quantiteDisponible} unités',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Ajouté le: ${DateFormat('dd/MM/yyyy').format(widget.produit.dateCreation)}',
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: widget.onOrder,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6C56F9),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'COMMANDER CE PRODUIT',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
