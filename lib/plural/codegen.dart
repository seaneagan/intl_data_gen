// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library intl_data_gen.plural.codegen;

import 'package:codegen/codegen.dart';
import 'package:intl_data_gen/intl_data_gen.dart';
import 'package:path/path.dart';
import 'package:intlx/src/plural/plural.dart';
import 'package:cldr/src/util.dart';
import 'package:intl_data_gen/src/util.dart';
import 'package:intl_data_gen/plural/plural_rule_parser.dart';

class PluralCodeGen extends IntlCodeGen {

  static var logger = getLogger('PluralCodeGen');

  final String type = "plural";
  final String symbolsClass = "PluralLocaleImpl";
  final String symbolsClassLibraryName = "plural";

  PluralCodeGen(PathGenerator pathGenerator) : super(pathGenerator);

  void writeLibrariesSync(){
    super.writeLibrariesSync();
    new LogStep(logger, "Writing loadLocale() library")
      .execute(writeLoadLocaleLibrary);
  }

  void writeLoadLocaleLibrary() {
    var loadLocaleLibraryPath = join(PubPackage.SRC, type);

    var deferredLibraries = localeList.map((locale) =>
      '''const library_$locale = const DeferredLibrary('plural_symbols_$locale');
''').join();

    var libraryMapEntries = localeList.map((locale) =>
      '''  '$locale': library_$locale''').join(',\n');

    var switchCases = localeList.map((locale) =>
      '''      case '$locale': init(${getSymbolsVariable(locale)}); break;
''').join();

    var code = '''
$deferredLibraries

  const libraryMap = const <String, DeferredLibrary> {
$libraryMapEntries
  };

Future<bool> loadLocale([String locale]) {
  if(PluralLocaleImpl.map.containsKey(locale)) return new Future.value(false);
  return libraryMap[locale].load().then((_) {
    init(PluralLocale pluralLocale) => 
      PluralLocaleImpl.map[locale] = pluralLocale;
    switch(locale) {
$switchCases
    }
    return true;
  });
}''';

    var imports = [
      'dart:async',
      'package:${package.name}/src/util.dart',
      'package:${package.name}/src/plural/plural.dart'
    ]
    .map((uri) => new Import(uri))
    .toList()
    ..addAll(localeList.map((locale) {
      var symbolsImportId = getSymbolsImportPrefix(locale);
      return new Import(
        package.getPackageUri('src/plural/data/$locale.dart'),
        as: symbolsImportId,
        metadata: '@library_$locale');
    }));

    new Library(
      join(package.path, loadLocaleLibraryPath, "${type}_load_locale.dart"),
      code,
      imports,
      comment: getLibraryComment(false))..generate();
  }

  String getSymbolsConstructorArgs(String locale, Map data) =>
    """'$locale', (int n) {
${getPluralRulesCode(data)}
}""";

List<Import> get symbolsLibraryImports =>
  [
    super.symbolsLibraryImports,
    [new Import(package.getPackageUri('src/util.dart'))]
  ].expand((i) => i).toList();
}

String getPluralRulesCode(Map<String, String> pluralRules) =>
  PluralCategory.values.reversed.skip(1).fold(
    "return PluralCategory.OTHER;",
    (String code, category) {
      var categoryString = category.toString();
      if(pluralRules.containsKey(categoryString)) {
        String categoryTest =
          pluralParser.parse(pluralRules[categoryString]).toDart();
        code = '''if($categoryTest) return PluralCategory.${categoryString};
  else $code''';
      }
      return code;
  });
