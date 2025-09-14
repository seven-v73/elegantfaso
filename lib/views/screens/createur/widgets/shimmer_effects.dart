import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerGrid extends StatelessWidget {
  const ShimmerGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: 5,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            height: 70,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      },
    );
  }
}

class ShimmerDashboard extends StatelessWidget {
  const ShimmerDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 1.2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: List.generate(4, (index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              )),
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 20,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                ),
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  childAspectRatio: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  children: List.generate(4, (index) => Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  )),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 150,
                  height: 20,
                  color: Colors.white,
                  margin: const EdgeInsets.only(bottom: 12),
                ),
                Container(
                  height: 300,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
