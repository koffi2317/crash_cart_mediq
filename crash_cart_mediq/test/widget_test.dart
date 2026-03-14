import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:crash_cart_mediq/main.dart'; // Vérifie que le nom du package est correct

void main() {
  testWidgets('Test d\'affichage de la page d\'importation', (WidgetTester tester) async {
    // 1. Charger l'application
    await tester.pumpWidget(const CrashCartMediqApp());

    // 2. Vérifier que le titre de l'application est présent
    // Remplace par le texte exact que tu as mis dans ton AppBar
    expect(find.text('Analyse des fichiers médicaux'), findsOneWidget);

    // 3. Vérifier que le bouton d'importation existe
    expect(find.byIcon(Icons.upload_file), findsOneWidget);
    expect(find.text('Importer un fichier (.csv ou .xlsx)'), findsOneWidget);

    // 4. Vérifier qu'au début, il n'y a pas encore de résultats
    expect(find.byType(ListTile), findsNothing);
  });
}