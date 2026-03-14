import 'dart:io';
import 'dart:convert'; 
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'detector.dart';
import 'models.dart'; 

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

  // ---------------- CSV ----------------
  Future<void> _readCsv(String path) async {
    final input = File(path).openRead();
    final csv = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    if (csv.isEmpty) return;

    csv.removeAt(0); // En-tête
    _processRows(csv);
  }

  // ---------------- EXCEL ----------------
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

  // ---------------- TRAITEMENT ----------------
  void _processRows(List<List<dynamic>> rows) {
    final detector = Detector();

    for (var row in rows) {
      if (row.length < 13) continue; // IMPORTANT : 13 colonnes maintenant

      var ligne = LigneData(
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
        volumePerfusion: double.tryParse(row[12].toString()) ?? 0, // 👈 AJOUT ESSENTIEL
      );

      var resultat = detector.analyser(ligne);

      setState(() {
        resultats.add(resultat);
      });
    }
  }

  // ---------------- RESET ----------------
  void clearFile() {
    setState(() {
      fileName = 'Aucun fichier importé';
      resultats.clear();
    });
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Analyse des fichiers médicaux'),
        backgroundColor: Colors.blueGrey,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: pickFile,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Importer'),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: clearFile,
                  icon: const Icon(Icons.delete),
                  label: const Text('Effacer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Fichier : $fileName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: resultats.length,
                itemBuilder: (context, index) {
                  var r = resultats[index];
                  bool isError = r["status"] == "error";
                  bool isWarning = r["status"] == "warning";

                  return Card(
                    color: isError
                        ? Colors.red[50]
                        : isWarning
                            ? Colors.yellow[100]
                            : Colors.green[50],
                    child: ListTile(
                      leading: Icon(
                        isError
                            ? Icons.error
                            : isWarning
                                ? Icons.warning
                                : Icons.check_circle,
                        color: isError
                            ? Colors.red
                            : isWarning
                                ? Colors.orange
                                : Colors.green,
                      ),
                      title: Text("Patient ${r["patient"]} — ${r["heure"]}"),
                      subtitle: Text("${r["message"]} (${r["type"]})"),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
