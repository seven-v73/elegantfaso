import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:elegantfaso/models/boutique/boutique_product.dart';

class BoutiqueProductCard extends StatelessWidget {
  final BoutiqueProduct product;
  final VoidCallback onTap;

  const BoutiqueProductCard({
    Key? key,
    required this.product,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(10)),
                child: product.imageUrl.isNotEmpty
                    ? CachedNetworkImage(
                  imageUrl: product.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                )
                    : Container(
                  color: Colors.grey[200],
                  child: Center(
                    child: Icon(Icons.shopping_bag, size: 40),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${product.price} FCFA',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.category, size: 14),
                      SizedBox(width: 4),
                      Text(
                        product.category,
                        style: TextStyle(fontSize: 12),
                      ),
                      Spacer(),
                      Icon(Icons.inventory, size: 14),
                      SizedBox(width: 4),
                      Text(
                        product.stock.toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}