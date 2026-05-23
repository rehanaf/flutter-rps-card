import 'package:flutter/material.dart';

class CollectionHeader extends StatelessWidget {
  final int totalCards;
  final String titleText;

  const CollectionHeader({
    super.key,
    required this.totalCards,
    required this.titleText,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Tombol Kembali Kustom Bertema Emas
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFC5A059), size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        
        // Judul Screen
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              titleText.toUpperCase(),
              style: const TextStyle(
                color: Color(0xFFC5A059),
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              "$totalCards KARTU DIMILIKI",
              style: const TextStyle(
                color: Colors.white30,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ],
    );
  }
}