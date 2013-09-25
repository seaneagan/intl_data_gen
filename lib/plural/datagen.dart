// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library intl_data_gen.plural.datagen;

import 'package:cldr/cldr.dart';
import 'package:cldr/data_sets.dart';
import 'package:intl_data_gen/intl_data_gen.dart';

class PluralDataGen extends IntlDataGen {

  PluralDataGen(JsonExtractor extractor, PathGenerator pathGenerator)
      : super(extractor, plurals, pathGenerator);

  transform(String locale, Map data) => data.keys.fold({}, (pluralCategoryMap, key) {
    // store plural categories in upper case form
    // to match the output of PluralCategory.toString()
    var pluralCategory =
        key.substring("pluralRule-count-".length).toUpperCase();
    pluralCategoryMap[pluralCategory] = data[key];
    return pluralCategoryMap;
  });
}
