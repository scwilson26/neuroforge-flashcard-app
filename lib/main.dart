import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:async';

// Web-specific imports
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

// Mobile-specific imports
import 'package:file_picker/file_picker.dart';
import 'dart:io';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroForge Flashcards',
      home: Scaffold(
        appBar: AppBar(title: Text('NeuroForge Study Pack Generator')),
        body: FlashcardUploader(),
      ),
    );
  }
}

class FlashcardUploader extends StatefulWidget {
  const FlashcardUploader({super.key});

  @override
  _FlashcardUploaderState createState() => _FlashcardUploaderState();
}

class _FlashcardUploaderState extends State<FlashcardUploader> {
  String status = "No file selected.";
  Uint8List? fileBytes;
  String? fileName;
  double uploadProgress = 0.0;
  bool showDownloadButton = false;

  void pickFile() async {
    if (kIsWeb) {
      final uploadInput = html.FileUploadInputElement()..accept = '.pdf';
      uploadInput.click();

      uploadInput.onChange.listen((event) {
        final file = uploadInput.files!.first;
        final reader = html.FileReader();

        reader.onLoadEnd.listen((e) {
          setState(() {
            fileBytes = reader.result as Uint8List;
            fileName = file.name;
            status = "Selected: $fileName";
            showDownloadButton = false;
          });
        });

        reader.readAsArrayBuffer(file);
      });
    } else {
      FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.custom, allowedExtensions: ['pdf']);
      if (result != null) {
        final pickedFile = result.files.first;
        setState(() {
          fileBytes = pickedFile.bytes;
          fileName = pickedFile.name;
          status = "Selected: $fileName";
          showDownloadButton = false;
        });
      }
    }
  }

  Future<void> generateZip() async {
    if (fileBytes == null) return;

    setState(() {
      status = "Uploading...";
      uploadProgress = 0.0;
    });

    Timer? progressTimer;
    progressTimer = Timer.periodic(Duration(milliseconds: 100), (_) {
      setState(() {
        if (uploadProgress < 0.95) {
          uploadProgress += 0.01;
        }
      });
    });

    final uri = Uri.parse('http://127.0.0.1:8000/generate-study-pack');
    final request = http.MultipartRequest('POST', uri);
    request.files.add(http.MultipartFile.fromBytes('file', fileBytes!, filename: fileName));

    try {
      final streamedRequest = await request.send();
      final data = await streamedRequest.stream.toBytes();

      progressTimer.cancel();
      setState(() => uploadProgress = 1.0);

      if (streamedRequest.statusCode == 200) {
        if (kIsWeb) {
          final blob = html.Blob([data]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          final anchor = html.AnchorElement(href: url)
            ..setAttribute("download", "study_pack.zip")
            ..click();
          html.Url.revokeObjectUrl(url);

          await Future.delayed(Duration(milliseconds: 500));
        } else {
          // Show message for mobile (add actual file saving logic if needed)
          print("✅ File received. You can now handle it on mobile.");
        }

        setState(() {
          status = "✅ Study pack ready!";
          uploadProgress = 0.0;
          showDownloadButton = true;
        });
      } else {
        setState(() {
          status = "❌ Failed to generate.";
          uploadProgress = 0.0;
        });
      }
    } catch (e) {
      progressTimer.cancel();
      setState(() {
        status = "❌ Error during upload";
        uploadProgress = 0.0;
      });
      print("❌ Upload failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(status),
          if (uploadProgress > 0.0 && uploadProgress < 1.0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                child: LinearProgressIndicator(value: uploadProgress),
              ),
            ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: pickFile,
            child: Text('Select PDF'),
          ),
          SizedBox(height: 10),
          ElevatedButton(
            onPressed: generateZip,
            child: Text('Generate Study Pack (.zip)'),
          ),
        ],
      ),
    );
  }
}
