
/// This library contains things which aren't really specific to this package,
/// but don't currently exist in any common libraries.
library intl_data_gen.util;

import 'dart:async';
import 'package:logging/logging.dart';

// TODO: replace with resolution of http://dartbug.com/9590
Map mapValues(Map map, valueMapper(value)) => map.keys.fold({}, (result, key) {
  result[key] = valueMapper(map[key]);
  return result;
});

/// Allows one to log the start and end of a logical step in a DRY manner
class LogStep {
  final Logger _logger;
  final String _description;
  final Level _level;
  LogStep(this._logger, this._description, {Level level: Level.INFO})
      : _level = level;

  /// logs the start of the step
  start() => _logBoundary("START");

  /// logs the end of the step
  end() => _logBoundary("END  ");

  /// The step as defined by [f] is [start]ed, executed, and then [end]ed,
  /// which if [f] returns a [Future], will not occur until its completion.
  execute(f()) {
    start();
    var ret = f();
    if(ret is Future) return ret.then((v) {
      end();
      return v;
    }, onError: (e) {_logger.severe("FAIL STEP: $_description");});
    end();
    return ret;
  }

  _logBoundary(String boundary) =>
      _logger.log(_level, "$boundary STEP: $_description");
}

/// Converts first character of [s] to uppercase if [capitalized] is true, or
/// otherwise lowercase.
String withCapitalization(String s, bool capitalized) {
  var firstLetter = s[0];
  firstLetter = capitalized ?
      firstLetter.toUpperCase() :
      firstLetter.toLowerCase();
  return firstLetter + s.substring(1);
}

/// Converts an underscore separated String, [underscores], to camel case.
/// e.g. "foo_bar" -> "fooBar" or "FooBar" (capitalized == true)
String underscoresToCamelCase(String underscores, bool capitalized) {
  var camel = underscores.splitMapJoin(
      "_",
      onMatch: (_) => "",
      onNonMatch: (String segment) => withCapitalization(segment, true));
  return withCapitalization(camel, capitalized);
}

// TODO: Move this implementation into Intl.shortLocale.
String baseLocale(String aLocale) {
  final noSeparators = new RegExp(r'[^_-]*');
  return noSeparators.stringMatch(aLocale.toLowerCase());
}
