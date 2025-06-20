import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'mood_input_screen.dart';
import 'history_screen.dart';
import 'stats_screen.dart';
import 'edit_mood_screen.dart'; // NÃO ESQUEÇA DE IMPORTAR!

Future<DocumentSnapshot?> getTodayMood() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return null;

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);
  final endOfDay = startOfDay.add(Duration(days: 1));

  final query = await FirebaseFirestore.instance
      .collection('moods')
      .where('userId', isEqualTo: user.uid)
      .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
      .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
      .limit(1)
      .get();

  if (query.docs.isNotEmpty) {
    return query.docs.first;
  } else {
    return null;
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  void _logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Bem-vindo')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Olá, ${user?.email ?? "usuário"}!'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _logout(context),
              child: const Text('Logout'),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              child: const Text('Registrar Humor'),
              onPressed: () async {
                final doc = await getTodayMood();
                if (doc == null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MoodInputScreen()),
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditMoodScreen(
                        docId: doc.id,
                        initialEmotion: doc['emotion'],
                        initialDescription: doc['description'],
                      ),
                    ),
                  );
                }
              },
            ),
            ElevatedButton(
              child: const Text('Histórico'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              child: const Text('Estatísticas'),
              onPressed:
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const StatsScreen()),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
