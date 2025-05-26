import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  Color getMoodColor(String mood) {
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
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Humor'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection('moods')
                .where(
                  'userId',
                  isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                )
                .orderBy('timestamp', descending: true)
                .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Erro no Firestore: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final moods = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: moods.length,
            itemBuilder: (context, index) {
              final mood = moods[index];
              final date = mood['timestamp'].toDate();
              final formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(date);

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: getMoodColor(mood['emotion']),
                    child: Text(
                      mood['emotion'][0],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(mood['emotion']),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mood['description'].toString().isNotEmpty)
                        Text(mood['description']),
                      Text(formattedDate, style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
