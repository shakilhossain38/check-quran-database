import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({
    super.key,
  });

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: isLoading ? const CircularProgressIndicator() : _selectFileWidget(),
    );
  }

  Widget _selectFileWidget() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(),
          InkWell(
            onTap: _showDialog,
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.teal.shade700,
                  borderRadius: BorderRadius.circular(10)),
              child: const Padding(
                padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Upload file',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(
                      width: 10,
                    ),
                    Icon(Icons.file_present_outlined, color: Colors.white)
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(),
        ],
      ),
    );
  }

  Future<List<dynamic>> pickAndReadJsonFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result != null && result.files.single.path != null) {
      String filePath = result.files.single.path!;

      File file = File(filePath);
      String fileContent = await file.readAsString();

      Map<String, dynamic> decodedJson = jsonDecode(fileContent);

      int newValue = 0;
      int totalValue = 0;

      Map<int, int> missingAyahMap = {};

      Map<int, int> incorrectAyahTextMap = {};

      for (var i = 0; i < decodedJson['ayat'].length; i++) {
        for (var j = 0; j < decodedJson['ayat'][i].length; j++) {
          totalValue += 1;

          int currentAyahNumber = decodedJson['ayat'][i][j]['verse_number'];

          if (newValue + 1 != currentAyahNumber) {
            if ((currentAyahNumber - (newValue + 1)) > 1) {
              missingAyahMap[currentAyahNumber] = newValue + 1;
            }
          }

          if (decodedJson['ayat'][i][j]['text'].toString().isNotEmpty &&
              !decodedJson['ayat'][i][j]['text']
                  .toString()
                  .contains('$currentAyahNumber')) {
            incorrectAyahTextMap[currentAyahNumber] = newValue + 1;
          }

          newValue += 1;
        }
      }

      return [missingAyahMap, incorrectAyahTextMap, totalValue];
    } else {
      return [];
    }
  }

  Future<void> _showDialog() async {
    final result = await pickAndReadJsonFile();
    isLoading = true;
    setState(() {});
    String missingAyah = '';
    String incorrectAyah = '';
    if (result.first.isNotEmpty) {
      List<dynamic> missingEntries = result.first.entries
          .map((entry) => '${entry.key} -> ${entry.value}')
          .toList();

      missingAyah = 'Missing ayah numbers: [${missingEntries.join(', ')}]';
    } else {
      missingAyah = 'No ayah numbers are missing.';
    }
    if (result[1].isNotEmpty) {
      List<dynamic> incorrectTextEntries =
          result[1].entries.map((entry) => '${entry.key}').toList();
      incorrectAyah =
          'Ayahs with incorrect text: [${incorrectTextEntries.join(', ')}]';
    } else {
      incorrectAyah = 'No issues with ayah text.';
    }
    Widget contentWidget() {
      return SizedBox(
        height: 100,
        width: 400,
        child: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('Total ayah count is ${result.last}'),
              const SizedBox(
                height: 5,
              ),
              Text(missingAyah),
              const SizedBox(
                height: 5,
              ),
              Text(incorrectAyah),
              const SizedBox(
                height: 5,
              ),
            ],
          ),
        ),
      );
    }

    isLoading = false;
    setState(() {});
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: const EdgeInsets.all(20),
          child: contentWidget(),
        );
      },
    );
  }
}
