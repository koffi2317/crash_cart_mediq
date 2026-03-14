import 'models.dart';

class Detector {
  late int Fr, Sat, Fc, Tas, Tad, idPatient;
  late double Temp, dose, concentration, volumePerfusion;
  late String administration, medicament, heure;

  Map<int, double> lastDose = {};

  // --- LISTE BLANCHE : Volumes Bolus autorisés > 5ml ---
  static const Set<String> _bolusDoseExemptions = {
    "Dextrose",
    "Bicarbonate de sodium",
    "Bicarbonnate de sodium",
    "Chlorure de calcium",
    "Soluté physiologique",
    "Albumine",
    "Mannitol",
    "Magnésium",
    "Potassium",
  };

  // --- LIMITES IM SPÉCIFIQUES ---
  static const Map<String, double> _imDoseLimits = {
    "Épinéphrine": 0.5,
    "Atropine": 1.0,
  };

  Map<String, dynamic> analyser(LigneData row) {
    // 1. Nettoyage et sécurisation des données
    Fr = int.tryParse(row.fr.toString()) ?? 0;
    Sat = int.tryParse(row.sat.toString()) ?? 0;
    Fc = int.tryParse(row.fc.toString()) ?? 0;
    Tas = int.tryParse(row.tas.toString()) ?? 0;
    Tad = int.tryParse(row.tad.toString()) ?? 0;
    Temp = double.tryParse(row.temp.toString()) ?? 0.0;
    dose = row.dose;
    concentration = row.concentration;
    volumePerfusion = row.volumePerfusion;
    administration = row.administration.trim();
    medicament = row.medicament.trim();
    idPatient = int.tryParse(row.idPatient.toString()) ?? 0;
    heure = row.heure;

    double quantiteMg = dose * concentration;

    // ================================================================
    // BLOC A — COHÉRENCE PHYSIQUE (ERREURS ROUGES)
    // ================================================================

    // A1. Tension impossible
    if (Tas > 0 && Tad > 0 && Tas <= Tad) {
      return error("illogicalVitals", "Tension impossible : TAS ($Tas) ≤ TAD ($Tad)");
    }

    // A2. Température absurde
    if (Temp > 42.5 || (Temp < 30.0 && Temp > 0)) {
      return error("illogicalVitals", "Température non physiologique ($Temp °C)");
    }

    // A3. Perfusion sans volume
    if (administration.toLowerCase().contains("perfusion") && concentration > 0 && volumePerfusion <= 0) {
      return error("illogicalData", "Perfusion : Volume manquant pour $medicament");
    }

    // ================================================================
    // BLOC B — SÉCURITÉ MÉDICAMENTEUSE (ERREURS ROUGES)
    // ================================================================

    // B1. Validation de la Quantité Totale (Mg)
    // Exemple : Naloxone 0.4mg max
    if (medicament.toLowerCase().contains("naloxone") && quantiteMg > 0.41) {
      return error("wrongDose", "Quantité excessive : ${quantiteMg.toStringAsFixed(2)} mg (Max 0.4mg)");
    }

    // B2. Validation du Volume Bolus (Ml)
    if (administration.toLowerCase() == "bolus" && dose > 5) {
      bool exempted = _bolusDoseExemptions.any(
          (med) => medicament.toLowerCase().contains(med.toLowerCase()));
      if (!exempted) {
        return error("wrongDose", "Volume Bolus trop élevé : $dose ml");
      }
    }

    // B3. Validation IM
    if (administration.toLowerCase() == "im") {
      double limite = _imDoseLimits[medicament] ?? 3.0;
      if (dose > limite) {
        return error("wrongDose", "Volume IM trop élevé pour $medicament ($dose ml)");
      }
    }

    // B4. Omission de traitement (Naloxone requis)
    if (Fr < 8 && Sat < 90 && !medicament.toLowerCase().contains("naloxone")) {
      return error("wrongDrug", "Urgence : Naloxone requis (FR $Fr, SAT $Sat%)");
    }

    // ================================================================
    // BLOC C — ALERTES CLINIQUES (WARNING JAUNE)
    // ================================================================

    // C1. Fièvre
    if (Temp >= 38.0) {
      return warning("fièvre", "Fièvre détectée : $Temp °C");
    }

    // C2. État de choc suspecté
    if (Fc > 110 && Tas < 95 && Tas > 0) {
      return warning("clinicalAlert", "Signes de choc : FC $Fc bpm / TAS $Tas mmHg");
    }

    // C3. Hypoxie légère
    if (Sat > 0 && Sat < 92 && Fr >= 8) {
      return warning("hypoxie", "Saturation basse : $Sat %");
    }

    // Finalisation
    lastDose[idPatient] = dose;
    return ok();
  }

  // --- RÉPONSES ---
  Map<String, dynamic> ok() => {
    "status": "ok", "message": "Données normales", "patient": idPatient, "heure": heure
  };

  Map<String, dynamic> warning(String type, String msg) => {
    "status": "warning", "type": type, "message": msg, "patient": idPatient, "heure": heure
  };

  Map<String, dynamic> error(String type, String msg) => {
    "status": "error", "type": type, "message": msg, "patient": idPatient, "heure": heure
  };
}