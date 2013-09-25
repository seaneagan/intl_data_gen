
import 'dart:io';
import 'package:args/args.dart';
import 'package:cldr/cldr.dart';
import 'package:codegen/codegen.dart';
import 'package:intl_data_gen/intl_data_gen.dart';
import 'package:intl_data_gen/iterable/datagen.dart';
import 'package:intl_data_gen/iterable/codegen.dart';
import 'package:intl_data_gen/plural/datagen.dart';
import 'package:intl_data_gen/plural/codegen.dart';
import 'package:intl_data_gen/relative_time/datagen.dart';
import 'package:intl_data_gen/relative_time/codegen.dart';

main() {

  // Define args.
  var parser = new ArgParser();
  parser.addOption('cldr_json', help: 'The path to the Cldr json to use');
  parser.addOption(
      'intl_data_package',
      help: 'The path to the package in which intl data is to be stored');

  // Process args.
  var results = parser.parse(new Options().arguments);
  var cldrJson = results['cldr_json'];
  var extractor = new JsonExtractor(cldrJson);
  var intlDataPackagePath = results['intl_data_package'];
  var intlDataPackage = new PubPackage(intlDataPackagePath);

  // Generate intl data and code.
  var iterablePathGenerator = new PathGenerator(intlDataPackage, 'iterable');
  new IterableDataGen(extractor, iterablePathGenerator).generate();
  new IterableCodeGen(iterablePathGenerator).generate();
  var pluralPathGenerator = new PathGenerator(intlDataPackage, 'plural');
  new PluralDataGen(extractor, pluralPathGenerator).generate();
  new PluralCodeGen(pluralPathGenerator).generate();
  var relativeTimePathGenerator =
      new PathGenerator(intlDataPackage, 'relative_time');
  new RelativeTimeDataGen(extractor, relativeTimePathGenerator).generate();
  new RelativeTimeCodeGen(relativeTimePathGenerator).generate();
}
