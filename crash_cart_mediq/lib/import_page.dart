import 'dart:io';
import 'package:csv/csv.dart';
import 'package:excel/excel.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'detector.dart';

class ImportPage extends StatefulWidget {
  const ImportPage({super.key});

  @override
  State<ImportPage> createState() => _ImportPageState();
}

class _ImportPageState extends State<ImportPage> {
  String fileName = 'Aucun fichier importé';

  // Liste des résultats (chaque élément = Map)
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

  // -----------------------------
  // LECTURE CSV
  // -----------------------------
  Future<void> _readCsv(String path) async {
    final input = File(path).openRead();
    final csv = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    csv.removeAt(0); // retirer l’en-tête
    final detector = Detector();

    for (var row in csv) {
      var ligne = LigneData(
        idPatient: row[0],
        heure: row[1],
        fc: row[2],
        tas: row[3],
        tad: row[4],
        fr: row[5],
        sat: row[6],
        temp: row[7],
        medicament: row[8],
        dose: double.tryParse(row[9].toString()) ?? 0,
        concentration: double.tryParse(row[10].toString()) ?? 0,
        administration: row[11],
      );

      var resultat = detector.analyser(ligne);

      setState(() {
        resultats.add({
          "patient": ligne.idPatient,
          "heure": ligne.heure,
          "status": resultat["status"],
          "message": resultat["message"],
          "type": resultat["type"]
        });
      });
    }
  }

  // -----------------------------
  // LECTURE EXCEL
  // -----------------------------
  Future<void> _readExcel(String path) async {
    var bytes = File(path).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    final detector = Detector();

    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows.skip(1)) {
        if (row.length < 12) continue;

        var ligne = LigneData(
          idPatient: row[0]?.value ?? 0,
          heure: row[1]?.value ?? '',
          fc: row[2]?.value ?? 0,
          tas: row[3]?.value ?? 0,
          tad: row[4]?.value ?? 0,
          fr: row[5]?.value ?? 0,
          sat: row[6]?.value ?? 0,
          temp: row[7]?.value ?? 0,
          medicament: row[8]?.value ?? '',
          dose: double.tryParse(row[9]?.value.toString() ?? '0') ?? 0,
          concentration: double.tryParse(row[10]?.value.toString() ?? '0') ?? 0,
          administration: row[11]?.value ?? '',
        );

        var resultat = detector.analyser(ligne);

        setState(() {
          resultats.add({
            "patient": ligne.idPatient,
            "heure": ligne.heure,
            "status": resultat["status"],
            "message": resultat["message"],
            "type": resultat["type"]
          });
        });
      }
    }
  }

  // -----------------------------
  // UI
  // -----------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Analyse des fichiers médicaux')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ElevatedButton.icon(
              onPressed: pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Importer un fichier (.csv ou .xlsx)'),
            ),
            const SizedBox(height: 10),
            Text('Fichier sélectionné : $fileName'),
            const Divider(),

            // LISTE DES RÉSULTATS
            Expanded(
              child: ListView.builder(
                itemCount: resultats.length,
                itemBuilder: (context, index) {
                  var r = resultats[index];
                  bool ok = r["status"] == "ok";

                  return ListTile(
                    leading: Icon(
                      ok ? Icons.check_circle : Icons.error,
                      color: ok ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      "Patient ${r["patient"]} — ${r["heure"]}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ok ? Colors.green : Colors.red,
                      ),
                    ),
                    subtitle: Text(
                      ok ? "OK" : "${r["message"]} (${r["type"]})",
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
