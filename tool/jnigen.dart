import 'dart:io';

import 'package:jnigen/jnigen.dart';

Future<void> main(List<String> args) async {
  final packageRoot = Platform.script.resolve('../');

  final generator = JniGenerator(
    input: Input(
      // The specific class you want to generate bindings for
      classes: [
        'com.example.flutter_decision_maker_example.DecisionMakerBridge',
      ],
      // Explicitly map the paths where Flutter compiles your Kotlin code
      // To find the correct paths, you can check your build directory after a successful build.
      // in macOS/Linux: find build/app -name "DecisionMakerBridge.class"
      classPath: [
        packageRoot.resolve('build/app/tmp/kotlin-classes/release/'),
        packageRoot.resolve('build/app/tmp/kotlin-classes/debug/'),
      ],
      // Configuration to search for Android SDK libraries.
      androidSdk: AndroidSdk(addGradleDeps: true),
    ),
    output: Output(
      dart: DartOutput(
        // Output path for generated bindings
        path: packageRoot.resolve(
          'lib/src/generated/decision_maker_bindings.dart',
        ),
        // Write bindings into a single file (instead of one file per class).
        structure: OutputStructure.singleFile,
      ),
    ),
  );
  await generator.generate();
}
