import 'models.dart';

class Detector {
  // Variables de session pour les calculs
  late int Fr, Sat, Fc, Tas, Tad, idPatient;
  late double Temp, dose, concentration, volumePerfusion;
  late String administration, medicament, heure;

  Map<int, double> lastDose = {};

  Map<String, dynamic> analyser(LigneData row) {
    // 1. Conversion et sécurisation des données
    // Utilisation de double pour Temp pour gérer les virgules (ex: 36.5)
    Fr = int.tryParse(row.fr.toString()) ?? 0;
    Sat = int.tryParse(row.sat.toString()) ?? 0;
    Fc = int.tryParse(row.fc.toString()) ?? 0;
    Tas = int.tryParse(row.tas.toString()) ?? 0;
    Tad = int.tryParse(row.tad.toString()) ?? 0;
    Temp = double.tryParse(row.temp.toString()) ?? 0.0;
    
    dose = row.dose;
    concentration = row.concentration;
    volumePerfusion = row.volumePerfusion;
    administration = row.administration;
    medicament = row.medicament;
    idPatient = int.tryParse(row.idPatient.toString()) ?? 0;
    heure = row.heure;

    // --- RÈGLES DE SÉCURITÉ MÉDICAMENTEUSE ---

    // A. Vérification Volume vs Concentration (Critique pour Patient 2 - 11:02)
    if (concentration > 0 && volumePerfusion <= 0) {
      return error("illogicalData", "Concentration présente sans volume de perfusion");
    }

    // B. Mauvais médicament (Dépression respiratoire)
    if (Fr < 8 && Sat < 90 && medicament != "Naloxone") {
      return error("wrongDrug", "Urgence : Naloxone attendu (FR/SAT bas)");
    }

    // C. Doses critiques selon l'administration
    if (administration == "Bolus" && dose > 5) {
      return error("wrongDose", "Dose Bolus trop élevée (>5ml)");
    }
    if (administration == "IM" && dose > 3) {
      return error("wrongDose", "Dose IM trop élevée (>3ml)");
    }

    // --- RÈGLES SUR LES SIGNES VITAUX ---

    // D. Tension impossible (Critique pour Patient 1 - 10:17)
    if (Tas <= Tad && Tas != 0) {
      return error("illogicalVitals", "Tension impossible (TAS $Tas <= TAD $Tad)");
    }

    // E. Température (Jaune pour fièvre, Rouge pour impossible)
    if (Temp > 42.0 || Temp < 30.0) {
      return error("illogicalVitals", "Température non physiologique ($Temp°C)");
    }
    if (Temp >= 38.0) {
      return warning("Alerte Fièvre", "Le patient est fébrile ($Temp°C)");
    }

    // F. Cohérence Cardio-vasculaire
    if (Fc > 150 && Tas < 80) {
      return error("illogicalVitals", "Choc : FC élevée avec TA très basse");
    }
    if (Fc < 40 && Tas < 80) {
      return error("illogicalVitals", "Bradycardie sévère avec hypotension");
    }

    // G. Signes respiratoires contradictoires
    if (Fr < 5 && Sat > 95) {
      return error("illogicalVitals", "Incohérence : FR très basse avec SAT normale");
    }

    // H. Limites physiques extrêmes
    if (Fc < 20 || Fc > 220) {
      return error("illogicalVitals", "Fréquence cardiaque hors limites humaines");
    }

    // Mise à jour de la dernière dose si tout est OK
    lastDose[idPatient] = dose;

    return ok();
  }

  // --- RÉPONSES ---

  Map<String, dynamic> ok() {
    return {
      "status": "ok",
      "message": "Données cohérentes",
      "patient": idPatient,
      "heure": heure,
      "type": ""
    };
  }

  Map<String, dynamic> warning(String type, String msg) {
    return {
      "status": "warning", // Déclenchera la couleur Ambre/Jaune
      "type": type,
      "message": msg,
      "patient": idPatient,
      "heure": heure
    };
  }

  Map<String, dynamic> error(String type, String msg) {
    return {
      "status": "error", // Déclenchera la couleur Rouge
      "type": type,
      "message": msg,
      "patient": idPatient,
      "heure": heure
    };
  }
}