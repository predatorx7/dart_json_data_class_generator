import 'dart:convert';
import 'dart:io';

import 'package:dcg/constant.dart';
import 'package:dcg/dcg.dart';
import 'package:dcg/json_input.dart';

void main(List<String> args) {
  final hasInputFileName = args.length > 1;
  final String outputDartFileName;

  try {
    outputDartFileName = args[hasInputFileName ? 1 : 0];
  } on RangeError {
    print('Invalid output file name.\n$usage');
    exit(255);
  }

  final String inputJsonText;

  if (hasInputFileName) {
    try {
      final inputDartFileName = args[0];
      final file = File(inputDartFileName);
      inputJsonText = file.readAsStringSync();
    } on RangeError {
      print('Invalid input file name.\n$usage');
      exit(255);
    } on FileSystemException {
      print('Failed to read data from input file.\n$usage');
      exit(255);
    }
  } else {
    try {
      print('Input json: ');
      inputJsonText = getJsonInput();
    } catch (e, s) {
      print('Failed to read json.\n$usage');
      print('$e\n$s');
      exit(255);
    }
  }

  final data = json.decode(inputJsonText);

  final y = generateJsonSerializableDataClass(
    data,
  );

  final outputDartFile = File(outputDartFileName);
  outputDartFile.writeAsStringSync(
    y,
    mode: FileMode.append,
  );

  print(
    'Generated `json_serializable`s in $outputDartFileName',
  );
  print(dontForget);
}
