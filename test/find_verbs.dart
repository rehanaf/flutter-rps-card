import 'dart:convert';
import 'dart:io';

void main() {
  final file = File('assets/localization/data.json');
  if (!file.existsSync()) {
    print('Error: data.json not found');
    return;
  }

  final content = file.readAsStringSync();
  final list = json.decode(content) as List<dynamic>;

  final Map<String, int> verbFrequencies = {};

  for (var gesture in list) {
    final compares = gesture['compares'] as List<dynamic>;
    for (var comp in compares) {
      final verbList = comp['verb'] as List<dynamic>;
      final verbStr = verbList.join('|');
      verbFrequencies[verbStr] = (verbFrequencies[verbStr] ?? 0) + 1;
    }
  }

  final sorted = verbFrequencies.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  print('Top 60 most frequent verbs:');
  int covered = 0;
  for (int i = 0; i < 60 && i < sorted.length; i++) {
    final entry = sorted[i];
    covered += entry.value;
    print('${i + 1}. "${entry.key}": ${entry.value} times');
  }

  print('\nTop 60 covers $covered out of 5050 compares (${(covered / 5050 * 100).toStringAsFixed(1)}%)');
}
