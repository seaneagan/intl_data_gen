// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library intl_data_gen.iterable.code;

import 'package:path/path.dart';
import 'package:codegen/codegen.dart';
import 'package:intl_data_gen/intl_data_gen.dart';

class IterableCodeGen extends IntlCodeGen {
  final dataType = "iterable";
  final symbolsClass = "IterableSymbols";

  IterableCodeGen(PathGenerator pathGenerator) : super(pathGenerator);

  getSymbolsConstructorArgs(String locale, Map data) {

    String getConstructorArg(String type) {
      var separators = data[type];
      var innerArgs = separators.keys.map((String key) => "$key: '${separators[key]}'").join(", ");
      return '$type: new SeparatorTemplate($innerArgs)';
    }

    return ["start", "middle", "end", "two"].where(data.containsKey).map(getConstructorArg).join(""", 
""");
  }

  /// Get the Imports used by the symbols libraries.
  Iterable<Import> get symbolsLibraryImports => [
    super.symbolsLibraryImports,
    [new Import(package.getPackageUri(join("src", "cldr_template.dart")))]
  ].expand((i) => i);
}
