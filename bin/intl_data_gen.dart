
import 'package:intl_data_gen/iterable/datagen.dart';
import 'package:intl_data_gen/iterable/codegen.dart';

main() {
  new IterableDataGen().process();
  new IterableCodeGen().writeLibraries();
}
