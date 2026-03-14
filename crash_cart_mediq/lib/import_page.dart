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
  List<String> resultats = [];

  Future<void> pickFile() async {
    // Ouvre le sélecteur de fichiers
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
    );

    if (result == null) return; // utilisateur a annulé

    final path = result.files.single.path!;
    final name = result.files.single.name;

    setState(() {
      fileName = name;
      resultats.clear();
    });

    // Lecture du fichier selon son extension
    if (path.endsWith('.csv')) {
      await _readCsv(path);
    } else if (path.endsWith('.xlsx')) {
      await _readExcel(path);
    }
  }

  Future<void> _readCsv(String path) async {
    final input = File(path).openRead();
    final csv = await input.transform(utf8.decoder).transform(const CsvToListConverter()).toList();

    csv.removeAt(0); // retire l’en-tête
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
      var erreurs = detector.analyser(ligne);
      setState(() => resultats.add('Patient ${ligne.idPatient} (${ligne.heure}) : ${erreurs.join(", ")}'));
    }
  }

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
        var erreurs = detector.analyser(ligne);
        setState(() => resultats.add('Patient ${ligne.idPatient} (${ligne.heure}) : ${erreurs.join(", ")}'));
      }
    }
  }

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
            Expanded(
              child: ListView.builder(
                itemCount: resultats.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: const Icon(Icons.medication),
                    title: Text(resultats[index]),
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
