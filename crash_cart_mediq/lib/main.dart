import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'models.dart';
import 'detector.dart';

void main() {
  runApp(const MaterialApp(
    home: UploadPage(),
    debugShowCheckedModeBanner: false,
  ));
}

// ------------------------------------------------------------
// PAGE D’ACCUEIL : permet d’aller vers la page d’importation
// ------------------------------------------------------------
class UploadPage extends StatelessWidget {
  const UploadPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Téléversement de fichiers"),
        backgroundColor: Colors.blueGrey,
      ),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.upload_file),
          label: const Text("Importer un fichier"),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ImportPage()),
            );
          },
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// PAGE D’IMPORTATION : analyse CSV/XLSX + bouton retour + effacer
// ------------------------------------------------------------
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
    final name = result.files.single.name;

    setState(() {
      fileName = name;
      resultats.clear();
    });

    if (path.endsWith('.csv')) {
      await _readCsv(path);
    } else if (path.endsWith('.xlsx')) {
      await _readExcel(path);
    }
  }

  Future<void> _readCsv(String path) async {
    final bytes = await File(path).readAsBytes();
    final csv = const CsvToListConverter().convert(utf8.decode(bytes));

    if (csv.isEmpty) return;

    csv.removeAt(0);
    _processRows(csv);
  }

  Future<void> _readExcel(String path) async {
    var bytes = File(path).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);

    for (var table in excel.tables.keys) {
      var rows = excel.tables[table]!.rows
          .skip(1)
          .map((r) => r.map((c) => c?.value).toList())
          .toList();

      _processRows(rows);
    }
  }

  void _processRows(List<List<dynamic>> rows) {
    final detector = Detector();

    for (var row in rows) {
      if (row.length < 12) continue;

      var data = LigneData(
        idPatient: row[0],
        heure: row[1].toString(),
        fc: row[2],
        tas: row[3],
        tad: row[4],
        fr: row[5],
        sat: row[6],
        temp: row[7],
        medicament: row[8].toString(),
        dose: double.tryParse(row[9].toString()) ?? 0,
        concentration: double.tryParse(row[10].toString()) ?? 0,
        administration: row[11].toString(),
      );

      var res = detector.analyser(data);

      setState(() {
        resultats.add(res);
      });
    }
  }

  void clearFile() {
    setState(() {
      fileName = 'Aucun fichier importé';
      resultats.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      appBar: AppBar(
        title: const Text('Analyse des fichiers médicaux'),
        backgroundColor: Colors.blueGrey,

        // BOUTON RETOUR FONCTIONNEL
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: pickFile,
                  icon: const Icon(Icons.upload),
                  label: const Text("Importer"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: clearFile,
                  icon: const Icon(Icons.delete),
                  label: const Text("Effacer"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          Text(
            fileName,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),

          const Divider(),

          Expanded(
            child: ListView.builder(
              itemCount: resultats.length,
              itemBuilder: (context, i) {
                bool isErr = resultats[i]["status"] == "error";

                return Card(
                  color: isErr ? Colors.red[50] : Colors.green[50],
                  child: ListTile(
                    leading: Icon(
                      isErr ? Icons.warning : Icons.check_circle,
                      color: isErr ? Colors.red : Colors.green,
                    ),
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
