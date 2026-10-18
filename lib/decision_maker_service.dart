import 'dart:typed_data';

import 'package:jni/jni.dart';
import 'package:jni_flutter/jni_flutter.dart';

import 'src/generated/decision_maker_bindings.dart';

class DecisionMakerService {
  DecisionMakerBridge? _bridge;

  void init({
    String modelAsset = 'embeddinggemma-2-text-vision-440m.litertlm',
    int maxTokens = 512,
  }) {
    // Grab the global Android Application Context provided by package:jni_flutter
    final contextObj = androidApplicationContext;

    _bridge = DecisionMakerBridge(
      contextObj as Context, // Cast to Context
      modelAsset.toJString(),
      maxTokens,
    );
  }

  String evaluateMultimodal({
    required String prompt,
    required Uint8List imageBytes,
    required String jsonQuestions,
  }) {
    if (_bridge == null) {
      throw StateError('DecisionMakerService not initialized');
    }

    final jBytes = JByteArray.of(imageBytes);
    final jResult = _bridge!.evaluateMultimodalJson(
      prompt.toJString(),
      jBytes,
      jsonQuestions.toJString(),
    );

    return jResult.toDartString();
  }

  void dispose() {
    _bridge?.close();
    _bridge = null;
  }
}
