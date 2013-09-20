
part of intl_data_gen;

/// Defines a scheme for which paths to store and subsequently retrieve locale
/// data from.
class PathGenerator {

  /// The package for which paths are being generated.
  final PubPackage package;

  /// The root path of locale data.
  String get root => join(package.lib, 'data');

  /// A name for the type of data being output, used to construct
  /// a path relative to [root] to store the output.
  final String dataType;

  /// The filename extension to use for locale files.
  static final String _extension = 'json';

  PathGenerator(this.package, this.dataType);

  String get dataTypePath => join(root, dataType);

  String getLocalePath(String locale) => join(dataTypePath, "$locale.$_extension");
}
