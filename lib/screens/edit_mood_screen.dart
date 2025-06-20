import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditMoodScreen extends StatefulWidget {
  final String docId;
  final String initialEmotion;
  final String initialDescription;

  const EditMoodScreen({
    required this.docId,
    required this.initialEmotion,
    required this.initialDescription,
    Key? key,
  }) : super(key: key);

  @override
  State<EditMoodScreen> createState() => _EditMoodScreenState();
}

class _EditMoodScreenState extends State<EditMoodScreen> {
  late String selectedMood;
  late TextEditingController _descriptionController;

  final moods = [
    {'emoji': '😄', 'label': 'Feliz', 'color': Colors.amber},
    {'emoji': '😐', 'label': 'Neutro', 'color': Colors.grey},
    {'emoji': '😢', 'label': 'Triste', 'color': Colors.blue},
    {'emoji': '😠', 'label': 'Irritado', 'color': Colors.red},
    {'emoji': '😍', 'label': 'Apaixonado', 'color': Colors.pink},
  ];

  @override
  void initState() {
    super.initState();
    selectedMood = widget.initialEmotion;
    _descriptionController = TextEditingController(
      text: widget.initialDescription,
    );
  }

  void _saveEdit() async {
    await FirebaseFirestore.instance
        .collection('moods')
        .doc(widget.docId)
        .update({
          'emotion': selectedMood,
          'description': _descriptionController.text.trim(),
        });
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Registro atualizado!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Humor'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children:
                  moods.map((mood) {
                    final isSelected = mood['label'] == selectedMood;
                    return ChoiceChip(
                      avatar: Text(
                        mood['emoji'] as String,
                        style: const TextStyle(fontSize: 28),
                      ),
                      label: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Text(mood['label'] as String),
                      ),
                      selected: isSelected,
                      backgroundColor: Colors.grey.shade200,
                      selectedColor: (mood['color'] as Color).withOpacity(0.7),
                      onSelected: (_) {
                        setState(() {
                          selectedMood = mood['label'] as String;
                        });
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Descreva seu dia (opcional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.save),
              label: const Text('Salvar alterações'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _saveEdit,
            ),
          ],
        ),
      ),
    );
  }
}
