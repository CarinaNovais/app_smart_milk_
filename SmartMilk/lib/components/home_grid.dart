import 'package:flutter/material.dart';

class HomeGrid extends StatelessWidget {
  final List<GridItem> items;
  final int columns;
  final void Function(GridItem)? onItemTap; // callback opcional

  const HomeGrid({
    super.key,
    required this.items,
    this.columns = 2,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: Image.asset(item.imagePath, fit: BoxFit.scaleDown)),
            const SizedBox(height: 4),
            Text(
              item.legenda,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        );

        if (onItemTap != null) {
          return GestureDetector(onTap: () => onItemTap!(item), child: content);
        }

        return content; // só mostra, sem ação de toque
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
