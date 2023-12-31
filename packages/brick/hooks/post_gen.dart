import 'dart:async';
import 'dart:io';

import 'package:mason/mason.dart';
import 'package:path/path.dart' as path;

Future<void> run(HookContext context) async {
  final projectPath = path.join(
    Directory.current.path,
    context.vars['project_name'] as String,
  );
  final logger = context.logger;
  if (bool.tryParse('${context.vars['silent']}') ?? false) {
    logger.level = Level.quiet;
  }
  await runCommand(
    'melos bs',
    projectPath: projectPath,
    logger: logger,
    prefix: '📦 ',
    startMessage: 'Bootstrapping project.',
    completeMessage: 'Project bootstrapped!',
  );
  await runCommand(
    'melos run G',
    projectPath: projectPath,
    logger: logger,
    prefix: '🏭 ',
    startMessage: 'Running code generation.',
    completeMessage: 'Code generation complete!',
  );
  await runCommand(
    'dart fix --apply --code=directives_ordering',
    projectPath: projectPath,
    logger: logger,
    prefix: '🔧 ',
    startMessage: 'Applying fixes.',
    completeMessage: 'Fixes applied!',
  );
  await runCommand(
    'melos run F',
    projectPath: projectPath,
    logger: logger,
    prefix: '🪄  ',
    startMessage: 'Formatting code.',
    completeMessage: 'Code formatted!',
  );
}

Future<void> runCommand(
  String fullCommand, {
  required String projectPath,
  required Logger logger,
  required String prefix,
  required String startMessage,
  required String completeMessage,
}) async {
  final [command, ...args] = fullCommand.split(' ');
  const progressMessages = [
    'This may take a while',
    'Still working',
    'Almost there',
    'Just a little longer',
  ];
  final progress = logger.progress('$prefix$startMessage');
  final progressTimer = Timer.periodic(
    const Duration(milliseconds: 100),
    (timer) {
      final messageIndex = (timer.tick ~/ 50) % progressMessages.length;
      final message = progressMessages[messageIndex];
      progress.update('$prefix$startMessage $message');
    },
  );
  final result = await Process.run(
    command,
    args,
    workingDirectory: projectPath,
    runInShell: true,
  );
  if (result.exitCode != 0) {
    logger.alert(result.stderr?.toString());
    exit(result.exitCode);
  }
  progressTimer.cancel();
  progress.complete('$prefix$completeMessage');
}
