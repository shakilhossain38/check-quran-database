import 'dart:convert';
import 'dart:io';

import 'package:checker/string_resource.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _selectFileWidget(),
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

  Future<List<dynamic>> _pickAndReadJsonFile() async {
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

      return [
        missingAyahMap,
        incorrectAyahTextMap,
        decodedJson['id'],
        totalValue
      ];
    } else {
      return [];
    }
  }

  Future<void> _showDialog() async {
    final result = await _pickAndReadJsonFile();

    bool hasMissingAyah = false;
    bool hasMissingText = false;
    bool isCountEqual =
        StringResource.verseCounts['${result[2]}'] == '${result.last}';

    String missingAyah = '';
    String incorrectAyah = '';

    if (result.first.isNotEmpty) {
      List<dynamic> missingEntries = result.first.entries
          .map((entry) => '${entry.key} -> ${entry.value}')
          .toList();

      missingAyah = 'Missing ayah numbers : [${missingEntries.join(', ')}]';
      hasMissingAyah = true;
    } else {
      missingAyah = 'No ayah numbers are missing';
      hasMissingAyah = false;
    }
    if (result[1].isNotEmpty) {
      List<dynamic> incorrectTextEntries =
          result[1].entries.map((entry) => '${entry.key}').toList();
      incorrectAyah =
          'Ayahs with incorrect text : [${incorrectTextEntries.join(', ')}]';
      hasMissingText = true;
    } else {
      incorrectAyah = 'No issues with ayah text';
      hasMissingText = false;
    }

    bool hasErrorOnEntry = hasMissingAyah || hasMissingText || !isCountEqual;

    Widget contentWidget() {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: 200,
            width: 400,
            child: Center(
              child: Column(
                children: <Widget>[
                  _surahInfoWidget(result),
                  _checkItemWidget(
                    result,
                    hasErrorOnEntry,
                    missingAyah,
                    incorrectAyah,
                  ),
                  _okButton(),
                ],
              ),
            ),
          ),
          Positioned(
            top: -18,
            left: 190,
            child: _iconWidget(hasErrorOnEntry),
          ),
        ],
      );
    }

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

  Widget _surahInfoWidget(List<dynamic> result) {
    return Container(
      width: 400,
      decoration: const BoxDecoration(
        color: Colors.teal,
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(10),
          topLeft: Radius.circular(10),
        ),
      ),
      child: Column(
        children: [
          _commonSpaceWidget(),
          _commonSpaceWidget(),
          _commonSpaceWidget(),
          _commonSpaceWidget(),
          _commonTextWidget(
              'Surah name : ${StringResource.englishMeaning['${result[2]}']}'),
          _commonSpaceWidget(),
          _commonTextWidget(
              'Total ayah : ${StringResource.verseCounts['${result[2]}']}'),
          _commonSpaceWidget(),
          _commonSpaceWidget(),
        ],
      ),
    );
  }

  Widget _checkItemWidget(
    List<dynamic> result,
    bool hasErrorOnEntry,
    String missingAyah,
    String incorrectAyah,
  ) {
    return Expanded(
      child: Container(
        width: 400,
        decoration: BoxDecoration(
          color: hasErrorOnEntry ? Colors.red : Colors.green,
        ),
        child: Center(
          child: Column(
            children: [
              _commonSpaceWidget(),
              _commonSpaceWidget(),
              _commonTextWidget('Total ayah entered : ${result.last}'),
              _commonSpaceWidget(),
              _commonTextWidget(missingAyah),
              _commonSpaceWidget(),
              _commonTextWidget(incorrectAyah),
              _commonSpaceWidget(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconWidget(bool hasErrorOnEntry) {
    return Container(
      height: 35,
      width: 35,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Center(
        child: Icon(
          hasErrorOnEntry ? Icons.close : Icons.check,
          size: 25,
          color: hasErrorOnEntry ? Colors.red : Colors.green,
        ),
      ),
    );
  }

  Widget _commonSpaceWidget() {
    return const SizedBox(
      height: 5,
    );
  }

  Widget _commonTextWidget(String text) {
    const textStyle = TextStyle(color: Colors.white);
    return Text(text, style: textStyle);
  }

  Widget _okButton() {
    return SizedBox(
      width: 400,
      child: TextButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: const Text('Ok'),
      ),
    );
  }
}
