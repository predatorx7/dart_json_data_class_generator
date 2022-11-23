import 'dart:convert';
import 'dart:io';

String getJsonInput() {
  final buffer = StringBuffer();
  bool isValidJson() {
    if (buffer.isEmpty) return false;
    try {
      final data = json.decode(buffer.toString());
      return data != null;
    } on FormatException {
      return false;
    }
  }

  while (!isValidJson()) {
    print(buffer.toString());
    final data = stdin.readLineSync(retainNewlines: false);
    if (data == null) continue;
    buffer.writeln(data);
  }

  return buffer.toString();
}
