🚑 Crash Cart MedIQ
Crash Cart MedIQ est une application Flutter d'aide à la décision clinique conçue pour sécuriser l'administration des médicaments d'urgence. 
L'application analyse les signes vitaux et les protocoles médicamenteux en temps réel à partir de fichiers importés (CSV/Excel) pour détecter les erreurs de dosage, les incompatibilités de voies d'administration et les urgences vitales.

🌟 Fonctionnalités Clés
Import Intelligent : Support des fichiers .csv et .xlsx contenant les données patients.
Algorithme Detector : Un moteur d'analyse qui vérifie :
-La Dose Massique : Calcul automatique ($Dose \times Concentration$) pour valider la quantité réelle en mg.
-Les Voies d'Administration : Validation des volumes pour Bolus, IM, SC et Perfusion (ex: Calcium sur voie centrale obligatoire).
-La Cohérence des Signes Vitaux : Détection des tensions impossibles, bradycardies sévères ou chocs.
-Protocoles Spécifiques : Intégration des limites pour l'Adénosine, l'Atropine, l'Épinéphrine, etc.

Code Couleur de Sécurité : 
🔴 Rouge : Erreur critique (Dose toxique, voie interdite, donnée impossible).
🟡 Jaune : Alerte clinique (Fièvre, hypotension, effet attendu non atteint).
🟢 Vert : Données conformes aux protocoles.

🛠️ Installation
Prérequis
Flutter SDK (dernière version stable)

Android Studio / VS Code avec l'extension Flutter

Un émulateur Android ou un appareil physique

Clonage et Lancement
1.Cloner le dépôt :
git clone https://github.com/votre-utilisateur/crash_cart_mediq.git
cd crash_cart_mediq

2. Installer les dépendances :
flutter pub get

3.Lancer l'application :
flutter run

Structure du Fichier d'Importation
Pour que l'analyse soit optimale, le fichier CSV/Excel doit respecter l'ordre suivant :

1.ID Patient

2.Heure

3.Fréquence Cardiaque (FC)

4.Tension Systolique (TAS)

5.Tension Diastolique (TAD)

6.Fréquence Respiratoire (FR)

7.Saturation (SAT)

8.Température

9.Médicament

10.Dose (ml)

11.Concentration (mg/ml)

12.Mode d'administration

13.Volume de perfusion

🧠 Logique de l'Algorithme (Exemple)

L'application ne se contente pas de lire les données, elle applique une logique médicale stricte :

Cas du Naloxone : Si FR < 8 et SAT < 90%, le système vérifie la présence de Naloxone. Si la dose calculée (D X C) dépasse 0.4 mg, une alerte rouge est déclenchée pour éviter un sevrage brutal.

🤝 Contribution
Les contributions pour ajouter de nouveaux protocoles de médicaments sont les bienvenues !

Forkez le projet.

Créez votre branche (git checkout -b feature/ProtocolNewMed).

Modifiez le fichier lib/detector.dart.

Commitez vos changements.

Ouvrez une Pull Request.

⚖️ Licence
Ce projet est sous licence MIT. Pour un usage clinique réel, la validation par un professionnel de santé est obligatoire.



