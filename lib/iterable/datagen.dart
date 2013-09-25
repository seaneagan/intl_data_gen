// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library intl_data_gen.iterable.datagen;

import 'package:cldr/cldr.dart';
import 'package:cldr/data_sets.dart';
import 'package:intl_data_gen/intl_data_gen.dart';
import 'package:intl_data_gen/src/util.dart';
import 'package:intl_data_gen/src/cldr_template.dart';

class IterableDataGen extends IntlDataGen {

  IterableDataGen(JsonExtractor extractor, PathGenerator pathGenerator) : super(extractor, listPatterns, pathGenerator);

  transform(String locale, Map data) {

    var realData = data["listPattern"];
    // Make sure there are no "3" templates, Cldr claims to allow it,
    // but as of yet it hasn't appeared in the locales supported here.
    assert(!realData.containsKey("3"));

    // Rename "2" to "two", a valid Dart identifier.
    if(realData.containsKey("2")) {
      realData = new Map.from(realData);
      realData["two"] = realData["2"];
      realData.remove("2");
    }

    return mapValues(realData, SeparatorTemplate.parse);
  }
}
