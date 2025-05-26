import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:location/location.dart';
import '../services/weather_service.dart'; // <-- nosso serviço

class MoodInputScreen extends StatefulWidget {
  const MoodInputScreen({super.key});

  @override
  State<MoodInputScreen> createState() => _MoodInputScreenState();
}

class _MoodInputScreenState extends State<MoodInputScreen> {
  final TextEditingController _descriptionController = TextEditingController();
  String? selectedMood;

  double? _temperature;
  bool _loadingWeather = true;
  String? _weatherError;

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
    _loadWeather();
  }

  Future<void> _loadWeather() async {
    try {
      final loc = Location();
      final hasPerm = await loc.hasPermission();
      if (hasPerm == PermissionStatus.denied) {
        await loc.requestPermission();
      }
      final enabled = await loc.serviceEnabled() || await loc.requestService();
      if (!enabled) throw Exception('Serviço de localização desativado');

      final pos = await loc.getLocation();
      final temp = await WeatherService.fetchTemperature(
        lat: pos.latitude!,
        lon: pos.longitude!,
      );
      if (mounted) {
        setState(() {
          _temperature = temp;
          _loadingWeather = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _weatherError = e.toString();
          _loadingWeather = false;
        });
      }
    }
  }

  void _saveMood() async {
    if (selectedMood == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Selecione uma emoção!')));
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    try {
      await FirebaseFirestore.instance.collection('moods').add({
        'userId': user!.uid,
        'emotion': selectedMood,
        'description': _descriptionController.text.trim(),
        'timestamp': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Humor salvo com sucesso!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao salvar: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Como você está hoje?'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- seção de clima ---
            if (_loadingWeather)
              const Center(child: CircularProgressIndicator())
            else if (_weatherError != null)
              Center(child: Text('Erro clima: $_weatherError'))
            else
              Center(
                child: Text(
                  'Temperatura: ${_temperature!.toStringAsFixed(1)}°C',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // --- seleção de humor ---
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
              label: const Text('Salvar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: _saveMood,
            ),
          ],
        ),
      ),
    );
  }
}
