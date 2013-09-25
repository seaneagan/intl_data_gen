// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library intl_data_gen.relative_time.codegen;

import 'dart:convert';
import 'package:codegen/codegen.dart';
import 'package:cldr/src/util.dart';
import 'package:intl/intl.dart';
import 'package:intlx/intlx.dart';
import 'package:intlx/src/plural/plural_locale_list.dart';
import 'package:intl_data_gen/intl_data_gen.dart';

class RelativeTimeCodeGen extends IntlCodeGen {

  static var logger = getLogger('PluralCodeGen');

  final type = "relative_time";
  final symbolsClass = "RelativeTimeSymbols";

  RelativeTimeCodeGen(PathGenerator pathGenerator) : super(pathGenerator);

  String getPluralLibraryIdentifier(String locale) => "plural_locale_$locale";

  getSymbolsConstructorArgs(String locale, Map data) {
    String unitsCode(String unitType) {
      var units = data[unitType];
      var mapContents = '';
      if(!units.isEmpty) {
        mapContents = TimeUnit.values.map((TimeUnit unit) {
          var unitString = unit.toString();
          return '"$unitString": ${JSON.encode(units[unitString])}';
        }).join(''',
      ''');
      }
      return '''
  $unitType: {
      $mapContents
    }''';
    }

    var unitCategories = ["units", "shortUnits", "pastUnits", "futureUnits"];
    var ret = unitCategories.map(unitsCode).join(''',
    ''');
    return '''
    $ret''';
  }

  final pluralLocaleDataId = 'plural_locale_data';
  String get publicClassMarkdown => '[DurationFormat] and/or [AgeFormat]';
  List get symbolsImports {
    var plurlLocaleDataUri = 'package:${package.name}/$pluralLocaleDataId.dart';
    return [new Import(plurlLocaleDataUri, as: pluralLocaleDataId)]
    ..addAll(super.symbolsImports);
  }

  String getLocaleDataConstructorArgs(String locale) {
    var pluralLocaleId = Intl.verifiedLocale(
        locale,
        pluralLocales.contains,
        onFailure: (_) => 'root').toUpperCase();
    return super.getLocaleDataConstructorArgs(locale) +
        ", $pluralLocaleDataId.$pluralLocaleId";
  }

  String get symbolsMapSetterLogic => '''$pluralLocaleDataId.ALL.load();
${super.symbolsMapSetterLogic}''';
}
