// lib/platform/file_picker_mobile.dart
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

Future<Map<String, dynamic>?> pickFile() async {
  FilePickerResult? result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['pdf'],
  );
  if (result != null) {
    final pickedFile = result.files.first;
    return {
      'bytes': pickedFile.bytes,
      'name': pickedFile.name,
    };
  }
  return null;
}