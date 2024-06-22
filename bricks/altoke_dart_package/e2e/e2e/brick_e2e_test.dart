@Tags(['e2e'])
library brick_e2e_test;

import 'dart:async';
import 'dart:io';

import 'package:mason/mason.dart';
import 'package:monorepo_elements/monorepo_elements.dart';
import 'package:path/path.dart' as path;
import 'package:shell/shell.dart';
import 'package:test/test.dart';

Future<void> main() async {
  test(
    '''

GIVEN the Altoke Dart Package brick
WHEN the generation is run
THEN the generated outputs should be valid and testable
''',
    () async {
      final tempDir = Directory.systemTemp.createTempSync(
        'altoke-dart-package-e2e-test-',
      );
      addTearDown(() => tempDir.deleteSync(recursive: true));
      final directoryGeneratorTarget = DirectoryGeneratorTarget(tempDir);
      final altokeDartPackageVars = <String, dynamic>{
        'package_name': 'test_altoke_dart_package',
        'package_description': 'A test Altoke Dart package.',
        'use_code_generation': true,
      };
      await BrickGenerator.dartPackage.runFullGeneration(
        target: directoryGeneratorTarget,
        vars: altokeDartPackageVars,
      );
      final outputPath = path.join(
        directoryGeneratorTarget.dir.path,
        'test_altoke_dart_package',
      );
      final outputDir = Directory(outputPath);
      final coverageDir = Directory(path.join(outputPath, 'coverage'));
      final lcovFile = File(path.join(coverageDir.path, 'lcov.info'));
      await expectLater(
        Shell.dartFormat(
          outputDir,
          failOnChanges: true,
        ),
        completes,
      );
      await expectLater(
        Shell.dartAnalyze(
          outputDir,
          fatalInfos: true,
          fatalWarnings: true,
        ),
        completes,
      );
      await expectLater(
        Shell.dartTest(
          outputDir,
          coverageDirectory: coverageDir,
        ),
        completes,
      );
      await expectLater(
        Shell.formatCoverageAsLcov(
          input: coverageDir,
          output: lcovFile,
          reportOn: outputDir,
        ),
        completes,
      );
      await expectLater(
        Shell.checkCoverage(
          inputLcov: lcovFile,
          threshold: 100,
        ),
        completes,
      );
    },
    timeout: const Timeout(Duration(minutes: 5)),
  );
}
