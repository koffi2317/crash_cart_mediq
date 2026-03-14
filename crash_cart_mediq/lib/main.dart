import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'models.dart';
import 'detector.dart';

void main() => runApp(const MaterialApp(home: ImportPage(), debugShowCheckedModeBanner: false));

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});
  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  String fileName = 'Aucun fichier importé';
  List<Map<String, dynamic>> resultats = [];

  Future<void> pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );
    if (result == null) return;
    final path = result.files.single.path!;
    setState(() { fileName = result.files.single.name; resultats.clear(); });
    path.endsWith('.csv') ? await _readCsv(path) : await _readExcel(path);
  }

  Future<void> _readCsv(String path) async {
    final bytes = await File(path).readAsBytes();
    final csv = const CsvToListConverter().convert(utf8.decode(bytes));
    csv.removeAt(0);
    _processRows(csv);
  }

  Future<void> _readExcel(String path) async {
    var bytes = File(path).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    for (var table in excel.tables.keys) {
      var rows = excel.tables[table]!.rows.skip(1).map((r) => r.map((c) => c?.value).toList()).toList();
      _processRows(rows);
    }
  }

  void _processRows(List<List<dynamic>> rows) {
    final detector = Detector();
    for (var row in rows) {
      if (row.length < 12) continue;
      var data = LigneData(
        idPatient: row[0], heure: row[1].toString(),
        fc: row[2], tas: row[3], tad: row[4], fr: row[5], sat: row[6], temp: row[7],
        medicament: row[8].toString(),
        dose: double.tryParse(row[9].toString()) ?? 0,
        concentration: double.tryParse(row[10].toString()) ?? 0,
        administration: row[11].toString(),
      );
      var res = detector.analyser(data);
      setState(() => resultats.add(res));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('MEDIQ Crash Cart Monitor'), backgroundColor: Colors.blueGrey),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(onPressed: pickFile, icon: const Icon(Icons.upload), label: const Text("Importer Fichier")),
          ),
          Text(fileName, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          Expanded(
            child: ListView.builder(
              itemCount: resultats.length,
              itemBuilder: (context, i) {
                bool isErr = resultats[i]["status"] == "error";
                return Card(
                  color: isErr ? Colors.red[50] : Colors.green[50],
                  child: ListTile(
                    leading: Icon(isErr ? Icons.warning : Icons.check_circle, color: isErr ? Colors.red : Colors.green),
                    title: Text("Patient ${resultats[i]["patient"]} - ${resultats[i]["heure"]}"),
                    subtitle: Text(resultats[i]["message"]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}