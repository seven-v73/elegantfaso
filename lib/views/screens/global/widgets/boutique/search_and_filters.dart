import 'package:flutter/material.dart';

class SearchAndFilters extends StatelessWidget {
  const SearchAndFilters({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          const TextField(
            decoration: InputDecoration(
              hintText: 'Rechercher des produits...',
              prefixIcon: Icon(Icons.search),
              suffixIcon: Icon(Icons.tune),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(25)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: 'Tous',
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  items: ['Tous', 'Pagnes', 'Boubous', 'Accessoires', 'Chaussures']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: 'Prix',
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  items: ['Prix', 'Croissant', 'Décroissant', 'Popularité']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (value) {},
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}