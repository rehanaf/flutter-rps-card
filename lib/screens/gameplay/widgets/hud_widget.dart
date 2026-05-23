import 'package:flutter/material.dart';
import '../../../models/status_effect.dart';

class HudWidget extends StatelessWidget {
  final String name;
  final int hp;
  final int maxHp;
  final bool isEnemy;
  final int shield;
  final List<StatusEffect> activeEffects;

  const HudWidget({
    super.key,
    required this.name,
    required this.hp,
    required this.maxHp,
    required this.isEnemy,
    this.shield = 0,
    this.activeEffects = const [],
  });

  @override
  Widget build(BuildContext context) {
    final double hpPercent = (hp / maxHp).clamp(0.0, 1.0);
    
    // Mengambil mediaQuery landscape agar lebar bar dinamis di tablet/HP
    final Size screenSize = MediaQuery.of(context).size;
    
    // RESPONSIVE RATIO: Lebar bar HP disesuaikan proporsional terhadap layar landscape
    final double barWidth = screenSize.width * 0.16; // Sekitar 140 - 160px mendatar
    final double barHeight = barWidth * 0.10;        // Tinggi bar proporsional

    // Komponen Susunan Efek Status Aktif di Bawah HP Bar
    Widget buildStatusEffectsList() {
      if (activeEffects.isEmpty) return const SizedBox.shrink();

      return Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Wrap(
          spacing: 5,
          runSpacing: 3,
          alignment: isEnemy ? WrapAlignment.end : WrapAlignment.start,
          children: activeEffects.map((effect) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2.5),
              decoration: BoxDecoration(
                color: effect.badgeColor.withAlpha(204),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: effect.isBuff ? Colors.white30 : Colors.redAccent.withAlpha(80),
                  width: 1.0,
                ),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 2, offset: Offset(0, 1)),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    effect.icon,
                    color: Colors.white,
                    size: barHeight * 0.6,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    "${effect.value}",
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'Electrolize',
                      fontWeight: FontWeight.bold,
                      fontSize: barHeight * 0.55,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      );
    }

    // Komponen Susunan Bar HP + Teks yang Menimpa tepat di tengah
    Widget buildHpBarWithText() {
      return Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(barWidth, barHeight),
            painter: ParallelogramHpBarPainter(
              percent: hpPercent,
              isEnemy: isEnemy,
            ),
          ),
          // Teks Keterangan HP Menimpa di Atas Bar
          Padding(
            padding: EdgeInsets.symmetric(horizontal: barWidth * 0.05),
            child: FittedBox(
              fit: BoxFit.scaleDown, // Amankan teks angka darah agar tidak meluap keluar jajar genjang
              child: Text(
                '$hp / $maxHp',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: barHeight * 0.65, // Ukuran teks proporsional terhadap tinggi bar
                  fontFamily: 'Electrolize',
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                      offset: Offset(1.0, 1.0),
                      blurRadius: 2,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Komponen Avatar Lingkaran (Skala Responsif)
    Widget buildAvatar() {
      final double avatarSize = screenSize.width * 0.085; // Menyesuaikan diameter lingkaran secara adaptif
      
      return Container(
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: isEnemy ? Colors.redAccent : const Color(0xFFC5A059),
            width: avatarSize * 0.04, // Tebal border proporsional
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 6,
              offset: Offset(0, 3),
            )
          ],
        ),
        child: ClipOval(
          child: Image.asset(
            isEnemy ? 'assets/images/enemy/avatar.jpg' : 'assets/images/player/avatar.jpg',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: const Color(0xFF1E1E1E),
                child: Icon(
                  isEnemy ? Icons.brightness_auto : Icons.person,
                  color: Colors.white54,
                  size: avatarSize * 0.5,
                ),
              );
            },
          ),
        ),
      );
    }

    return Container(
      color: Colors.transparent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        textDirection: isEnemy ? TextDirection.rtl : TextDirection.ltr,
        children: [
          buildAvatar(),
          SizedBox(width: screenSize.width * 0.015),
          
          // Detail Info (Nama & Bar HP Jajar Genjang)
          Column(
            crossAxisAlignment: isEnemy ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                textDirection: isEnemy ? TextDirection.rtl : TextDirection.ltr,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: barHeight * 1.0, // Skala nama mengikuti rasio tinggi bar darah
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (shield > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: Colors.blue[900]!.withAlpha(217),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue[300]!, width: 1.2),
                        boxShadow: const [
                          BoxShadow(color: Colors.black26, blurRadius: 3, offset: Offset(0, 1.5)),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.shield,
                            color: Colors.blue[100]!,
                            size: barHeight * 0.8,
                          ),
                          const SizedBox(width: 1),
                          Text(
                            "$shield",
                            style: TextStyle(
                              color: Colors.white,
                              fontFamily: 'Electrolize',
                              fontWeight: FontWeight.bold,
                              fontSize: barHeight * 0.75,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ]
                ],
              ),
              SizedBox(height: barHeight * 0.2),
              buildHpBarWithText(),
              buildStatusEffectsList(),
            ],
          ),
        ],
      ),
    );
  }
}

class ParallelogramHpBarPainter extends CustomPainter {
  final double percent;
  final bool isEnemy;

  ParallelogramHpBarPainter({required this.percent, required this.isEnemy});

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // Tingkat kemiringan potongan jajar genjang proporsional terhadap lebar bar
    final double skew = width * 0.085; 

    final Paint bgPaint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final Path bgPath = Path();
    if (!isEnemy) {
      bgPath.moveTo(skew, 0);
      bgPath.lineTo(width, 0);
      bgPath.lineTo(width - skew, height);
      bgPath.lineTo(0, height);
    } else {
      bgPath.moveTo(0, 0);
      bgPath.lineTo(width - skew, 0);
      bgPath.lineTo(width, height);
      bgPath.lineTo(skew, height);
    }
    bgPath.close();
    canvas.drawPath(bgPath, bgPaint);

    if (percent > 0) {
      final Paint fillPaint = Paint()
        ..color = isEnemy ? Colors.redAccent : Colors.green
        ..style = PaintingStyle.fill;

      final double fillWidth = width * percent;
      final Path fillPath = Path();

      if (!isEnemy) {
        fillPath.moveTo(skew, 0);
        double topX = fillWidth + skew;
        if (topX > width) topX = width;
        fillPath.lineTo(topX, 0);
        
        double bottomX = fillWidth;
        if (bottomX > width - skew) bottomX = width - skew;
        fillPath.lineTo(bottomX, height);
        fillPath.lineTo(0, height);
      } else {
        final double startX = width - fillWidth;
        double topX = startX - skew;
        if (topX < 0) topX = 0;
        fillPath.moveTo(topX, 0);
        fillPath.lineTo(width - skew, 0);
        fillPath.lineTo(width, height);
        
        double bottomX = startX;
        if (bottomX < skew) bottomX = skew;
        fillPath.lineTo(bottomX, height);
      }
      fillPath.close();
      canvas.drawPath(fillPath, fillPaint);
    }

    final Paint borderPaint = Paint()
      ..color = isEnemy ? const Color(0x66FF5252) : const Color(0xB3C5A059)
      ..style = PaintingStyle.stroke
      ..strokeWidth = height * 0.1; // Tebal border proporsional terhadap tinggi bar darah
    
    canvas.drawPath(bgPath, borderPaint);
  }

  @override
  bool shouldRepaint(covariant ParallelogramHpBarPainter oldDelegate) {
    return oldDelegate.percent != percent || oldDelegate.isEnemy != isEnemy;
  }
}