// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of intl_data_gen;

abstract class IntlDataGen {

  static var logger = getLogger("intl_data_gen.IntlDataGen");

  final cldrJsonPath = new Options().arguments.first;
  JsonExtractor get extractor => new JsonExtractor(cldrJsonPath);
  final PathGenerator pathGenerator;
  PubPackage get intlDataPackage => pathGenerator.package;

  IntlDataGen(this.pathGenerator);

  /// Returns a Map from locales to locale data.
  fetch();

  /// Transforms [localeData] for a given [locale] as necessary.
  transform(String locale, localeData) => localeData;

  /// Extracts, transforms, and stores locale data.
  process() {
    logger.info('=== Build ${pathGenerator.dataType} data ===');
    var extracted = new LogStep(logger, "extract locale data from CLDR")
        .execute(fetch);
    var transformed = new LogStep(logger, "transform locale data")
        .execute(() => _transform(extracted));
    new LogStep(logger, "store locale data")
        .execute(() => _store(transformed));
  }

  /// Performs [transform] for each supported locale, and returns a
  /// Map of transformed locale data.
  _transform(Map<String, dynamic> localeJsonMap) {
    var transformedData = localeJsonMap.keys.fold({}, (map, locale) {
      var transformedJson = transform(locale, localeJsonMap[locale]);
      logger.fine("""transformed locale data for '$locale' was:
$transformedJson""");
      map[locale] = transformedJson;
      return map;
    });

    // Remove any subtags which have identical data as their base tag.
    //
    // This minimizes the amount of data that needs to be loaded
    // when supporting multiple (or all) locales.  This is necessary since
    // our Ldml2JsonConverter output, uses the default -r (resolved) option,
    // which introduces duplication between tag and subtag.  Ldml2JsonConverter
    // also supports unresolved data (-r false), but it's much easier to
    // implement de-duplication here, than subtag data resolution.
    transformedData = transformedData.keys.fold({}, (map, String locale) {
      var localeData = transformedData[locale];
      var baseTag = baseLocale(locale);
      var keepData = true;
      if(baseTag != locale) {
        var baseTagData = transformedData[baseTag];
        var matcher = equals(baseTagData);
        var matchState = {};
        if(matcher.matches(localeData, matchState)) {
          logger.info("Removing data for '$locale' as it's identical to "
              "that of it's base tag '$baseTag'");
          keepData = false;
        } else {
          var description = matcher.describeMismatch(
              localeData, new StringDescription(), matchState, true);
          logger.info("Retaining data for '$locale' as it's different than "
              """that of it's base tag '$baseTag' as follows:
$description""");
        }
      }
      if(keepData) {
        map[locale] = localeData;
      }
      return map;
    });

    // Stringify remaining data.
    transformedData.forEach((locale, data) {
      transformedData[locale] = JSON.encode(data);
    });

    return transformedData;
  }

  /// Store the transformed data into the local file system for later usage.
  void _store(Map<String, String> localeJsonMap) {

    // Delete existing files.
    truncateDirectorySync(new Directory(pathGenerator.dataTypePath));

    // Store new files.
    localeJsonMap.forEach((locale, json){
      var localePath = pathGenerator.getLocalePath(locale);
      var dataFile = new File(localePath);
      logger.fine("storing data for locale '$locale' in '$localePath'");
      dataFile.directory.createSync(recursive: true);
      dataFile.writeAsStringSync(json);
    });
  }
}
