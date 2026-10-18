import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'decision_maker_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(home: DecisionMakerScreen()));
}

class DecisionMakerScreen extends StatefulWidget {
  const DecisionMakerScreen({super.key});

  @override
  State<DecisionMakerScreen> createState() => _DecisionMakerScreenState();
}

class _DecisionMakerScreenState extends State<DecisionMakerScreen> {
  final _service = DecisionMakerService();
  final ImagePicker _picker = ImagePicker();

  String _status = 'Ready';
  Uint8List? _selectedImageBytes;
  Map<String, dynamic>? _results;

  final String _questionsSchema = jsonEncode({
    "questions": {
      "screen_issue": {
        "type": "choice",
        "instructions": "Classify the hardware issue visible in the photo.",
        "criteria": {
          "cracked_screen": "Physical glass crack or shattered OLED panel.",
          "water_damage": "Liquid corrosion or condensation.",
        },
      },
      "urgency": {
        "type": "boolean",
        "condition":
            "The device is inoperable or poses a physical safety risk.",
      },
    },
  });

  @override
  void initState() {
    super.initState();
    _service.init();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024, // Optional: scale down to save memory
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _selectedImageBytes = bytes;
          _results = null; // Clear previous results
          _status = 'Image selected. Ready to evaluate.';
        });
      }
    } catch (e) {
      setState(() => _status = 'Error picking image: $e');
    }
  }

  Future<void> _runInference() async {
    if (_selectedImageBytes == null) {
      setState(() => _status = 'Please select an image first.');
      return;
    }

    setState(() => _status = 'Evaluating...');

    try {
      // Execute the JNI evaluation synchronously on the main isolate
      // Note: For production, consider wrapping this in Isolate.run() to avoid UI jank
      final rawJson = _service.evaluateMultimodal(
        prompt: "Analyze the provided image of the device.",
        imageBytes: _selectedImageBytes!,
        jsonQuestions: _questionsSchema,
      );

      setState(() {
        _status = 'Completed';
        _results = jsonDecode(rawJson) as Map<String, dynamic>;
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Decision Maker (Image Picker)')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Gallery'),
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (_selectedImageBytes != null)
              Expanded(
                flex: 1,
                child: Image.memory(_selectedImageBytes!, fit: BoxFit.contain),
              ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _selectedImageBytes != null ? _runInference : null,
              child: const Text('Evaluate Multimodal Decision'),
            ),

            const SizedBox(height: 16),
            Text(
              'Status: $_status',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),
            if (_results != null)
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  child: Text(
                    const JsonEncoder.withIndent('  ').convert(_results),
                    style: const TextStyle(fontFamily: 'monospace'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
