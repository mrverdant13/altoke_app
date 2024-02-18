import 'dart:io';

import 'package:collection/collection.dart';
import 'package:mason/mason.dart';

enum Database {
  hive('Hive', 'hive'),
  isar('Isar', 'isar'),
  realm('Realm', 'realm'),
  sembast('Sembast', 'sembast'),
  sqlite('SQLite', 'sqlite'),
  ;

  const Database(this.label, this.varIdentifier);

  final String label;
  final String varIdentifier;

  static Database select({
    required HookContext context,
  }) {
    final logger = context.logger;
    final candidateVarIdentifier = Platform.environment['ALTOKE_PROJECT_DB'];
    final candidate = Database.values.firstWhereOrNull(
      (database) => database.varIdentifier == candidateVarIdentifier?.trim(),
    );
    final selectedDatabase = candidate ??
        logger.chooseOne<Database>(
          'Which database do you want to use?',
          choices: Database.values,
          display: (database) => database.label,
        );
    for (final database in Database.values) {
      context.vars['use_${database.varIdentifier}_database'] =
          database == selectedDatabase;
    }
    return selectedDatabase;
  }
}
