@Tags(['e2e'])
library brick_e2e;

// import 'dart:io' as io;
import 'dart:io' show Directory, Process, Stdin, Stdout, systemEncoding;

import 'package:mason/mason.dart';
import 'package:meta/meta.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

class MockStdin extends Mock implements Stdin {}

class MockStdout extends Mock implements Stdout {}

void main() {
  testAppGeneration(
    '''

GIVEN the Altoke app brick
WHEN an app generation is run
THEN the generated app should be valid and testable
''',
    generationCases: {
      (routerPackageName: 'auto_route'),
      (routerPackageName: 'go_router'),
    },
  );
}

typedef AppGenerationCase = ({String routerPackageName});

@isTest
Future<void> testAppGeneration(
  String description, {
  required Set<AppGenerationCase> generationCases,
}) async {
  for (final generationCase in generationCases) {
    final (:routerPackageName) = generationCase;
    final composedDescription = '''

${description.trim()}
=> with `$routerPackageName`
''';
    test(
      composedDescription,
      () async {
        // final terminalStdout = io.stdout;
        // final mockStdin = MockStdin();
        // final mockStdout = MockStdout();
        // final mockStderr = MockStdout();
        // IOOverrides.runZoned(
        //   () async {
        registerFallbackValue(systemEncoding);
        // when(() => mockStdout.supportsAnsiEscapes).thenReturn(true);
        final rootDir = Directory.current.parent.parent;
        final brickPath = path.joinAll([rootDir.path, 'packages', 'brick']);
        final brick = Brick.path(brickPath);
        final masonGenerator = await MasonGenerator.fromBrick(brick);
        final tempDirectory = Directory.systemTemp.createTempSync(
          'altoke-app-e2e-test-$routerPackageName-',
        );
        final directoryGeneratorTarget =
            DirectoryGeneratorTarget(tempDirectory);

        // HACK: Bypass the `preGen` hook by setting the `vars` directly.
        // This is required since the logger provided to the `preGen` hook
        // does not seem to be the same that the logger injected in the
        // `HookContext` of the pre-gen hook implementation.
        // See: https://discord.com/channels/649708778631200778/846830668386271263/1148828740785295450
        final projectName = 'e2e_app_$routerPackageName';
        final projectDescription = 'E2E App (with `$routerPackageName`).';
        final vars = <String, dynamic>{
          'silent': true,
          'project_name': projectName,
          'project_description': projectDescription,
          'use_${routerPackageName}_router': true,
        };
        // var stepIndex = 0;
        // when(mockStdin.readLineSync).thenReturn(
        //   () {
        //     final value = switch (stepIndex) {
        //       0 => 'e2e_app_$routerPackageName',
        //       1 => 'E2E App (with `$routerPackageName`).',
        //       2 => routerPackageName,
        //       _ => null
        //     };
        //     stepIndex++;
        //     return value;
        //   }(),
        // );
        // await masonGenerator.hooks.preGen(
        //   workingDirectory: directoryGeneratorTarget.dir.path,
        //   vars: vars,
        //   onVarsChanged: (updatedVars) {
        //     vars
        //       ..clear()
        //       ..addAll(updatedVars);
        //   },
        // );

        await masonGenerator.generate(
          directoryGeneratorTarget,
          vars: vars,
        );
        await masonGenerator.hooks.postGen(
          workingDirectory: directoryGeneratorTarget.dir.path,
          vars: vars,
          onVarsChanged: (updatedVars) {
            vars
              ..clear()
              ..addAll(updatedVars);
          },
        );
        final applicationPath = path.join(
          directoryGeneratorTarget.dir.path,
          projectName,
        );
        const flutterTestFullCommand =
            '''flutter test --no-pub --coverage --test-randomize-ordering-seed random''';
        final [flutterTestCommand, ...flutterTestArgs] = flutterTestFullCommand
            .split(' ')
            .where((arg) => arg.isNotEmpty)
            .toList();
        final flutterTest = await Process.run(
          flutterTestCommand,
          flutterTestArgs,
          workingDirectory: applicationPath,
          runInShell: true,
        );
        expect(
          flutterTest.exitCode,
          equals(0),
          reason: '`flutter test` failed',
        );
        expect(
          flutterTest.stderr,
          isEmpty,
          reason: '`flutter test` failed',
        );
        const coverdeFilterFullCommand =
            '''coverde filter -i ./coverage/lcov.info -o coverage/filtered.lcov.info -f .g.dart,.gr.dart''';
        final [coverdeFilterCommand, ...coverdeFilterArgs] =
            coverdeFilterFullCommand
                .split(' ')
                .where((arg) => arg.isNotEmpty)
                .toList();
        final coverdeFilter = await Process.run(
          coverdeFilterCommand,
          coverdeFilterArgs,
          workingDirectory: applicationPath,
          runInShell: true,
        );
        expect(
          coverdeFilter.exitCode,
          equals(0),
          reason: '`coverde filter` failed',
        );
        expect(
          coverdeFilter.stderr,
          isEmpty,
          reason: '`coverde filter` failed',
        );
        const coverdeCheckFullCommand =
            '''coverde check -i coverage/filtered.lcov.info 100''';
        final [coverdeCheckCommand, ...coverdeCheckArgs] =
            coverdeCheckFullCommand
                .split(' ')
                .where((arg) => arg.isNotEmpty)
                .toList();
        final coverdeCheck = await Process.run(
          coverdeCheckCommand,
          coverdeCheckArgs,
          workingDirectory: applicationPath,
          runInShell: true,
        );
        expect(
          coverdeCheck.exitCode,
          equals(0),
          reason: '`coverde check` failed',
        );
        expect(
          coverdeCheck.stderr,
          isEmpty,
          reason: '`coverde check` failed',
        );
        tempDirectory.deleteSync(recursive: true);
        //   },
        //   stdin: () => mockStdin,
        //   stdout: () => mockStdout,
        //   stderr: () => mockStderr,
        // );
      },
      timeout: const Timeout(Duration(minutes: 5)),
    );
  }
}
