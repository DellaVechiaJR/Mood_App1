import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});
  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  String selectedEmotion = 'Todos';
  String selectedPeriod = 'Últimos 7 dias';

  final emotionsList = [
    'Todos',
    'Feliz',
    'Neutro',
    'Triste',
    'Irritado',
    'Apaixonado',
  ];
  final periodList = ['Últimos 7 dias', 'Mês Atual'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estatísticas'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedEmotion,
                    items:
                        emotionsList
                            .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => selectedEmotion = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: selectedPeriod,
                    items:
                        periodList
                            .map(
                              (p) => DropdownMenuItem(value: p, child: Text(p)),
                            )
                            .toList(),
                    onChanged: (v) => setState(() => selectedPeriod = v!),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<QuerySnapshot>(
                future: _fetchMoods(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Erro: ${snap.error}'));
                  }
                  final docs = snap.data!.docs;

                  // Conta cada emoção
                  final counts = <String, int>{
                    'Feliz': 0,
                    'Neutro': 0,
                    'Triste': 0,
                    'Irritado': 0,
                    'Apaixonado': 0,
                  };
                  for (var d in docs) {
                    final e = d['emotion'] as String;
                    if (counts.containsKey(e)) counts[e] = counts[e]! + 1;
                  }

                  final maxCount = counts.values.fold(
                    0,
                    (a, b) => a > b ? a : b,
                  );

                  if (maxCount == 0) {
                    return const Center(
                      child: Text('Nenhum dado para exibir.'),
                    );
                  }

                  return ListView(
                    children:
                        counts.entries.map((entry) {
                          final mood = entry.key;
                          final cnt = entry.value;
                          final pct = cnt / maxCount;

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                SizedBox(width: 80, child: Text(mood)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: FractionallySizedBox(
                                    widthFactor: pct,
                                    child: Container(
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _moodColor(mood),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(cnt.toString()),
                              ],
                            ),
                          );
                        }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<QuerySnapshot> _fetchMoods() {
    final user = FirebaseAuth.instance.currentUser!;
    var query = FirebaseFirestore.instance
        .collection('moods')
        .where('userId', isEqualTo: user.uid);

    if (selectedEmotion != 'Todos') {
      query = query.where('emotion', isEqualTo: selectedEmotion);
    }

    final now = DateTime.now();
    final start =
        selectedPeriod == 'Últimos 7 dias'
            ? now.subtract(const Duration(days: 7))
            : DateTime(now.year, now.month, 1);

    query = query.where(
      'timestamp',
      isGreaterThanOrEqualTo: Timestamp.fromDate(start),
    );

    return query.get();
  }

  Color _moodColor(String mood) {
    switch (mood) {
      case 'Feliz':
        return Colors.amber;
      case 'Neutro':
        return Colors.grey;
      case 'Triste':
        return Colors.blue;
      case 'Irritado':
        return Colors.red;
      case 'Apaixonado':
        return Colors.pink;
    }
    return Colors.black;
  }
}
