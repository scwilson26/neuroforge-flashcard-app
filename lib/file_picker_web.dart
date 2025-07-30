// lib/platform/file_picker_web.dart
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

Future<Map<String, dynamic>?> pickFile() async {
  final uploadInput = html.FileUploadInputElement()..accept = '.pdf';
  uploadInput.click();

  final completer = Completer<Map<String, dynamic>?>();
  uploadInput.onChange.listen((event) {
    final file = uploadInput.files!.first;
    final reader = html.FileReader();

    reader.onLoadEnd.listen((e) {
      completer.complete({
        'bytes': reader.result as Uint8List,
        'name': file.name,
      });
    });

    reader.readAsArrayBuffer(file);
  });

  return completer.future;
}