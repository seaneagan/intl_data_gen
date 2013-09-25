// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of intl_data_gen;

/// Uses json data to generate dart libraries which can be used
/// to load locale data of a given type.
abstract class IntlCodeGen {

  static var logger = getLogger("tool.cldr.library_writer");

  /// Intermediate storage of the locale data.
  Map<String, Map> localeDataMap;

  /// The list of locales for which data exists.
  List<String> localeList;

  /// A name for the type of data for which libraries are being written.
  String get dataType => jsonPathGenerator.dataType;

  /// The name of the dart class which represents this data type
  String get symbolsClass;

  /// The data path scheme.
  final PathGenerator jsonPathGenerator;

  /// The pub package for which code is being generated.
  PubPackage get package => jsonPathGenerator.package;

  IntlCodeGen(this.jsonPathGenerator);

  /// The name of the library in which [symbolsClass] will exist.
  String get symbolsClassLibraryName => '${dataType}_symbols';

  /// The main entry point. Gets the locale data using [getBuiltLocaleData]
  /// from which it then generates libraries using [writeLibrariesSync].
  generate() {
    logger.info("--- Build $dataType code ---");
    localeDataMap = new LogStep(logger, "Loading locale data")
        .execute(getBuiltLocaleData);
    localeList = new List.from(localeDataMap.keys)..sort();
    writeLibrariesSync();
  }

  /// Retrieves the input locale data from which to generate the locale data
  /// libraries.
  Map<String, dynamic> getBuiltLocaleData() {
    var dataDirectory = new Directory(jsonPathGenerator.dataTypePath);
    logger.info("locale data directory: ${dataDirectory.path}");
    return dataDirectory.listSync().fold({}, (localeDataMap, fse) {
      String locale = basenameWithoutExtension(fse.path);

      var filePath = jsonPathGenerator.getLocalePath(locale);
      var file = new File(filePath);
      String fileJson = file.readAsStringSync();
      localeDataMap[locale] = JSON.decode(fileJson);
      return localeDataMap;
    });
  }

  /// Generates all locale data libraries synchronously.
  void writeLibrariesSync() => {
    "Writing locale list library": writeLocaleListLibrary,
    "Writing symbols libraries": writeSymbolsLibraries,
    "Writing top-level locale data library": writeLocaleDataLibrary
  }.forEach((description, step) =>
      new LogStep(logger, description).execute(step));

  /// Write the library containing the list of supported locales for this
  /// data type.
  void writeLocaleListLibrary() {
    var localeListString = JSON.encode(localeList);

    var code = '''
const ${getLocaleListConstant()} = const <String> $localeListString;
''';

    new Library(
        join(package.src, dataType, "$localeListLibraryName.dart"),
        code,
        [],
        comment: getLibraryComment(false))
        .generate();

  }

  /// Writes the libraries containing raw locale data for each locale.
  void writeSymbolsLibraries() {

    // Delete existing data files.
    var localeSrcDirectory =
      new Directory(localeSrcPath);
    truncateDirectorySync(localeSrcDirectory);

    for(String locale in localeList) {
      writeSymbolsLibrary(locale, localeDataMap[locale]);
    }
  }

  /// Writes a library containing raw locale data for an individual locale.
  void writeSymbolsLibrary(String locale, Map data) {
    new Library(
        join(localeSrcPath, "${getLocaleId(locale)}.dart"),
        getSymbolLibraryCode(locale, data),
        symbolsLibraryImports,
        comment: getLibraryComment(true))
        .generate();
  }

  /// Returns the Imports used by the symbols libraries.
  Iterable<Import> get symbolsLibraryImports =>
      [new Import(package.getPackageUri(getSymbolsClassLibraryPath()))];

  /// Returns the code used by the symsols libraries.
  String getSymbolLibraryCode(String locale, Map data) {
    var constructorArgs = getSymbolsConstructorArgs(locale, data);
    return '''
final $symbolsConstantName = new $symbolsClass($constructorArgs);
''';
  }

  /// The name of the constant which stores symbols.
  final String symbolsConstantName = "symbols";

  /// Returns the constructor arguments to pass to [symbolsClass].
  String getSymbolsConstructorArgs(String locale, Map data);

  /// Returns an Import of a symbols library for a locale.
  Import getLocaleSymbolsImport(String locale) {
    var symbolsImportPrefix = getSymbolsImportPrefix(locale);
    var localeId = getLocaleId(locale);
    var uri = package.getPackageUri('src/$dataType/data/$localeId.dart');
    return new Import(uri, as: symbolsImportPrefix);
  }

  /// Returns the path of the library containing [symbolsClass].
  String getSymbolsClassLibraryPath() =>
      "src/$dataType/$symbolsClassLibraryName.dart";

  String get localeListLibraryName =>
      "${dataType}_locale_list";

  /// Returns dart project copyright text to use in generated dart files.  If
  /// [containsSymbols] is true, then the comment will also contain a warning
  /// that the file may have been manually edited before moving changes to CLDR
  /// and regenerating.
  String getLibraryComment(bool containsSymbols) {
    var comment = '''
// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// DO NOT EDIT. This file is autogenerated by script, see
// "package:intl_data_gen/bin/intl_data_gen.dart"
''';

    if(containsSymbols) {
      comment += '''
// 
// Before checkin, this file could have been manually edited. This is
// to incorporate changes before we could correct CLDR. All manual
// modification must be documented in this section, and should be
// removed after those changes land to CLDR.''';
    }
    return comment;
  }

  /// Markdown representing the public classes used to consume
  /// this locale data.
  String get publicClassMarkdown =>
      "[${underscoresToCamelCase(dataType, true)}Format]";

  /// Returns [Import]s of symbols libraries for each locale.
  List<Import> get symbolsImports =>
      localeList.map(getLocaleSymbolsImport).toList();

  /// Write the library representing the public interface for loading this
  /// locale data.
  writeLocaleDataLibrary() {
    var publicClasses = publicClassMarkdown;
    var dataPrefix = "${dataType}_data";
    var localeDataLibraryImport = new Import(
        package.getPackageUri(localeDataLibraryName), as: dataPrefix);
    var libraryDoc = '''

/// Exposes [LocaleData] constants for use with $publicClassMarkdown.
/// For example:
///     $localeDataLibraryImport
///     main() {
///       $dataPrefix.EN.load();
///       $dataPrefix.DE.load();
///       // do something with $publicClassMarkdown.
///     }''';

    var imports = [
      '${package.name}.dart',
      'src/locale_data_impl.dart',
      'src/symbols_map.dart',
      'src/$dataType/$localeListLibraryName.dart',
      getSymbolsClassLibraryPath()
    ]
        .map((path) => new Import(package.getPackageUri(path)))
        .toList()
        ..addAll(symbolsImports);

    var library = new Library(
        join(package.lib, localeDataLibraryName),
        '',
        imports,
        comment: getLibraryComment(false) + libraryDoc);
    // Add part which contains the ALL locale data constant.
    library.addPart(
        allLocaleDataPartPath,
        allLocaleDataPartCode,
        comment: getLibraryComment(false));
    // Add part which contains each individual locale data constant.
    library.addPart(
        localeDataConstantsPartPath,
        localeDataConstantsPartCode,
        comment: getLibraryComment(false));
    library.generate();

  }

  /// The name of the library representing the public interface
  /// for loading this locale data.
  String get localeDataLibraryName => "${dataType}_locale_data.dart";


  /// The path of the part containing the ALL locale data constant.
  String get allLocaleDataPartPath =>
      "src/$dataType/${dataType}_all_data_constant.dart";

  /// The code of the part containing the ALL locale data constant.
  String get allLocaleDataPartCode => '''
/// Loads data for **all** supported locales
final LocaleData ALL = new AllLocaleDataImpl(() {
$symbolsMapSetterLogic
});''';

  /// The path of the part containing the individual locale data constants.
  String get localeDataConstantsPartPath =>
      "src/$dataType/${dataType}_locale_data_constants.dart";

  /// The code of the part containing the individual locale data constants.
  String get localeDataConstantsPartCode {
    var localeDataConstants = localeList.map(getLocaleDataConstant).join("\n");
    return '''$localeDataConstants
''';
  }

  /// Returns constructor args for a LocaleData constant.
  String getLocaleDataConstructorArgs(String locale) =>
      '"$locale", () => ${getSymbolsVariable(locale)}';

  /// Returns the qualified name of the variable containing symbols data for
  /// [locale].
  String getSymbolsVariable(String locale) =>
      '${getSymbolsImportPrefix(locale)}.$symbolsConstantName';

  /// Returns the prefix used to import the symbols for [locale].
  String getSymbolsImportPrefix(String locale) =>
      "symbols_${getLocaleId(locale)}";

  /// Returns the logic used to set the SymbolsMap for this data type.
  String get symbolsMapSetterLogic {
    var symbolsMapContents = localeList.map((String locale) =>
        '  "$locale": ${getSymbolsVariable(locale)}').join(", \n");
    return '''
  $symbolsClass.map = new SymbolsMap<$symbolsClass>(
  ${getLocaleListConstant()}, 
  {$symbolsMapContents});''';
  }

  /// Returns the LocaleData constant for [locale].
  String getLocaleDataConstant(String locale) {
    var constructorArgs = getLocaleDataConstructorArgs(locale);
    var constructor = "${underscoresToCamelCase(dataType, true)}LocaleDataImpl";
    return '''final LocaleData ${getLocaleId(locale)} = 
    new $constructor($constructorArgs);''';
  }

  /// Returns the name of the constant representing the supported locale list.
  String getLocaleListConstant() =>
      '${underscoresToCamelCase(dataType, false)}Locales';

  /// Path of symbol libraries for given type.
  String get localeSrcPath => join(package.src, dataType, "data");

  /// Returns the dart identifier to use for [locale].  Must be uppercase
  /// since "in" and "is" are keywords.
  String getLocaleId(String locale) =>
      locale.toUpperCase().replaceAll('-', '_');
}
