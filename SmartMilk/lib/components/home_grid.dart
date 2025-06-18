import 'package:flutter/material.dart';

class HomeGrid extends StatelessWidget {
  final List<GridItem> items;
  final int columns;

  const HomeGrid({super.key, required this.items, this.columns = 2});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 colunas
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1, // quadrado
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return GestureDetector(
          onTap: () {
            Navigator.pushNamed(context, item.route);
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Image.asset(item.imagePath, fit: BoxFit.scaleDown),
              ),
              const SizedBox(height: 4),
              Text(
                item.legenda,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class GridItem {
  final String imagePath;
  final String route;
  final String legenda;

  GridItem({
    required this.imagePath,
    required this.route,
    required this.legenda,
  });
}
