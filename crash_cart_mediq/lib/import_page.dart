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

  // -----------------------------
  // LECTURE CSV
  // -----------------------------
  Future<void> _readCsv(String path) async {
    print("Début du chargement CSV...");
    final input = File(path).openRead();
    final csv = await input
        .transform(utf8.decoder)
        .transform(const CsvToListConverter())
        .toList();

    if (csv.isEmpty) {
      print("Erreur : Fichier CSV vide.");
      return;
    }

    csv.removeAt(0); // Retirer l'en-tête
    final detector = Detector();

    for (var row in csv) {
      if (row.length < 12) continue;
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
      );

      var resultat = detector.analyser(ligne);
      _updateUI(ligne, resultat);
    }
    
    // Print après la boucle pour confirmer la fin
    print("CSV chargé et analysé : ${csv.length} lignes traitées.");
  }

  // -----------------------------
  // LECTURE EXCEL
  // -----------------------------
  Future<void> _readExcel(String path) async {
    print("Début du chargement Excel...");
    var bytes = File(path).readAsBytesSync();
    var excel = Excel.decodeBytes(bytes);
    final detector = Detector();
    int count = 0;

    for (var table in excel.tables.keys) {
      for (var row in excel.tables[table]!.rows.skip(1)) {
        if (row.length < 12) continue;

        var ligne = LigneData(
          idPatient: row[0]?.value ?? 0,
          heure: row[1]?.value.toString() ?? '',
          fc: row[2]?.value ?? 0,
          tas: row[3]?.value ?? 0,
          tad: row[4]?.value ?? 0,
          fr: row[5]?.value ?? 0,
          sat: row[6]?.value ?? 0,
          temp: row[7]?.value ?? 0,
          medicament: row[8]?.value.toString() ?? '',
          dose: double.tryParse(row[9]?.value.toString() ?? '0') ?? 0,
          concentration: double.tryParse(row[10]?.value.toString() ?? '0') ?? 0,
          administration: row[11]?.value.toString() ?? '',
        );

        var resultat = detector.analyser(ligne);
        _updateUI(ligne, resultat);
        count++;
      }
    }
    print("Excel chargé et analysé : $count lignes traitées.");
  }

  void _updateUI(LigneData ligne, Map<String, dynamic> resultat) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analyse des fichiers médicaux'),
        backgroundColor: Colors.blueGrey,
      ),
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
            Text('Fichier : $fileName', style: const TextStyle(fontWeight: FontWeight.bold)),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: resultats.length,
                itemBuilder: (context, index) {
                  var r = resultats[index];
                  bool isError = r["status"] == "error";
                  return Card(
                    color: isError ? Colors.red[50] : Colors.white,
                    child: ListTile(
                      leading: Icon(
                        isError ? Icons.error : Icons.check_circle,
                        color: isError ? Colors.red : Colors.green,
                      ),
                      title: Text("Patient ${r["patient"]} — ${r["heure"]}"),
                      subtitle: Text("${r["message"]} ${isError ? '(${r["type"]})' : ''}"),
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