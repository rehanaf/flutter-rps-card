import 'package:flutter/material.dart';

class TooltipHelper {
  static Color getSynergyColor(String synergy) {
    switch (synergy.toLowerCase()) {
      case 'fire': return const Color(0xFFFF4500);
      case 'liquid': return const Color(0xFF1E90FF);
      case 'nature': return const Color(0xFF8B4513);
      case 'air': return const Color(0xFF87CEEB);
      case 'robot': return const Color(0xFF9DA5A8);
      case 'cosmic': return const Color(0xFF9370DB);
      case 'energy': return const Color(0xFFFFD700);
      case 'spirit': return const Color(0xFF00CED1);
      case 'dark': return const Color(0xFF4B0082);
      case 'ancient': return const Color(0xFFFFD700);
      case 'toxic': return const Color(0xFFADFF2F);
      default: return const Color(0xFFC5A059);
    }
  }

  static String getSynergyExplanation(String synergy) {
    switch (synergy.toLowerCase()) {
      case 'basic': return "Auto-Battler Synergy (Saat Dimainkan):\n[4] +2 Counter\n[8] +4 Counter, +1 Strength\n[12] +8 Counter, +3 Strength";
      case 'nature': return "Auto-Battler Synergy (Saat Dimainkan):\n[3] +2 Heal\n[6] +5 Heal\n[9] +10 Heal";
      case 'robot': return "Auto-Battler Synergy (Saat Dimainkan):\n[3] +3 Shield\n[6] +7 Shield\n[9] +15 Shield";
      case 'ancient': return "Auto-Battler Synergy (Saat Dimainkan):\n[2] +4 Shield\n[4] +8 Shield\n[6] +15 Shield";
      case 'spirit': return "Auto-Battler Synergy (Saat Dimainkan):\n[3] Weaken (1 Turn)\n[6] Weaken (2 Turn)\n[9] Weaken (4 Turn)";
      case 'fire': return "Auto-Battler Synergy (Saat Dimainkan):\n[2] DoT 3\n[4] DoT 7\n[6] DoT 12, Vulnerable (2 Turn)";
      case 'toxic': return "Auto-Battler Synergy (Saat Dimainkan):\n[2] DoT 2\n[4] DoT 5\n[6] DoT 10, Weaken (2 Turn)";
      case 'cosmic': return "Auto-Battler Synergy (Saat Dimainkan):\n[2] Vulnerable (1 Turn)\n[4] Vulnerable (2 Turn)\n[5] Vulnerable (4 Turn)";
      case 'liquid': return "Auto-Battler Synergy (Saat Dimainkan):\n[2] +1 Heal, +1 Shield\n[4] +3 Heal, +3 Shield\n[6] +6 Heal, +6 Shield";
      case 'energy': return "Auto-Battler Synergy (Saat Dimainkan):\n[1] +1 Strength\n[2] +3 Strength\n[3] +8 Strength";
      case 'air': return "Auto-Battler Synergy (Saat Dimainkan):\n[2] 15% Peluang Immunity\n[4] 30% Peluang Immunity\n[5] 50% Peluang Immunity";
      default: return "";
    }
  }

  static String getStatusEffectExplanation(String effectId) {
    switch (effectId.toLowerCase()) {
      case 'strength': return "Meningkatkan daya serang dasar secara permanen.";
      case 'shield': return "Menyerap damage yang akan diterima di awal giliran berikutnya.";
      case 'counter': return "Membalas penyerang dengan damage setiap kali menerima serangan.";
      case 'immunity': return "Kebal terhadap semua serangan dan debuff.";
      case 'dot': return "Damage over Time: Mengurangi HP target di awal gilirannya secara berkala.";
      case 'weaken': return "Kekuatan serangan berkurang sebesar 25%.";
      case 'vulnerable': return "Menerima damage serangan masuk 50% lebih besar.";
      case 'heal': return "Menyembuhkan HP secara instan.";
      case 'damagereduce': return "Kerusakan fisik yang diterima dikurangi.";
      default: return "Efek status khusus.";
    }
  }
}
