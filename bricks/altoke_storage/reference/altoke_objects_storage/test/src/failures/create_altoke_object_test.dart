import 'package:altoke_objects_storage/altoke_objects_storage.dart';
import 'package:test/test.dart';

void main() {
  test(
    'exports CreateAltokeObjectFailureEmptyName',
    () {
      expect(
        CreateAltokeObjectFailureEmptyName.new,
        returnsNormally,
      );
    },
  );
}
