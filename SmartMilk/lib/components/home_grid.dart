import 'dart:ui';
import 'package:flutter/material.dart';

class HomeGrid extends StatelessWidget {
  final List<GridItem> items;
  final int columns;
  final void Function(GridItem)? onItemTap;

  const HomeGrid({
    super.key,
    required this.items,
    this.columns = 2,
    this.onItemTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        final card = ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: (isDark ? Colors.white : Colors.white).withOpacity(
                  isDark ? 0.08 : 0.14,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.10),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(item.imagePath, fit: BoxFit.contain),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Text(
                      item.legenda,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? Colors.white.withOpacity(0.85)
                                : Colors.black.withOpacity(0.75),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        return GestureDetector(
          onTap: onItemTap != null ? () => onItemTap!(item) : null,
          child: card,
        );
      },
    );
  }
}

class GridItem {
  final String imagePath;
  final String route;
  final String legenda;

  const GridItem({
    required this.imagePath,
    required this.route,
    required this.legenda,
  });
}
