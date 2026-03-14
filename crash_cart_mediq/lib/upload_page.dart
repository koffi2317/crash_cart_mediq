import 'package:flutter/material.dart';
import 'import_page.dart';

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
