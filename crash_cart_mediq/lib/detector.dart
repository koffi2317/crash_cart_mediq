import 'models.dart';

class Detector {
  late int Fr, Sat, Fc, Tas, Tad, idPatient;
  late double Temp, dose, concentration, volumePerfusion;
  late String administration, medicament, heure;

  Map<int, double> lastDose = {};

  static const Set<String> _bolusDoseExemptions = {
    "dextrose",
    "bicarbonate de sodium",
    "bicarbonnate de sodium",
    "chlorure de calcium",
    "soluté physiologique",
    "albumine",
    "mannitol",
    "magnésium",
    "potassium",
  };

  static const Map<String, double> _imDoseLimits = {
    "épinéphrine": 0.5,
    "atropine": 1.0,
  };

  Map<String, dynamic> analyser(LigneData row) {
    Fr = int.tryParse(row.fr.toString()) ?? 0;
    Sat = int.tryParse(row.sat.toString()) ?? 0;
    Fc = int.tryParse(row.fc.toString()) ?? 0;
    Tas = int.tryParse(row.tas.toString()) ?? 0;
    Tad = int.tryParse(row.tad.toString()) ?? 0;
    Temp = double.tryParse(row.temp.toString()) ?? 0.0;
    dose = row.dose;
    concentration = row.concentration;
    volumePerfusion = row.volumePerfusion;
    administration = row.administration.trim().toLowerCase();
    medicament = row.medicament.trim().toLowerCase();
    idPatient = int.tryParse(row.idPatient.toString()) ?? 0;
    heure = row.heure;

    double quantiteMg = dose * concentration;

    // ================================================================
    // A — COHÉRENCE PHYSIQUE
    // ================================================================

    if (Tas > 0 && Tad > 0 && Tas <= Tad) {
      return error("illogicalVitals", "Tension impossible : TAS ($Tas) ≤ TAD ($Tad)");
    }

    if (Temp > 42.5 || (Temp < 30.0 && Temp > 0)) {
      return error("illogicalVitals", "Température non physiologique ($Temp °C)");
    }

    // Perfusion sans volume
    if (administration.contains("perfusion") && concentration > 0 && volumePerfusion <= 0) {
      return error("illogicalData", "Perfusion sans volume pour $medicament");
    }

    // ================================================================
    // B — COHÉRENCE DOSE / CONCENTRATION / VOLUME
    // ================================================================

    // B1. Vérification dose = C × V
    double doseCalculee = concentration * volumePerfusion;
    if (volumePerfusion > 0 && concentration > 0) {
      if ((doseCalculee - dose).abs() > 0.5) {
        return error("doseMismatch",
            "Dose incohérente : dose=$dose ml vs C×V=${doseCalculee.toStringAsFixed(2)}");
      }
    }

    // B2. Volume trop élevé pour un bolus
    if (administration == "bolus" && volumePerfusion > 20) {
      return error("wrongVolume", "Volume trop élevé pour un bolus : $volumePerfusion ml");
    }

    // B3. Volume trop faible pour une perfusion
    if (administration.contains("perfusion") && volumePerfusion < 20) {
      return error("wrongVolume", "Volume trop faible pour une perfusion : $volumePerfusion ml");
    }

    // ================================================================
    // C — SÉCURITÉ MÉDICAMENTEUSE
    // ================================================================

    // C1. Naloxone dose max
    if (medicament.contains("naloxone") && quantiteMg > 0.41) {
      return error("wrongDose", "Naloxone excessive : ${quantiteMg.toStringAsFixed(2)} mg (max 0.4 mg)");
    }

    // C2. Bolus > 5 ml sauf exceptions
    if (administration == "bolus" && dose > 5) {
      bool exempted = _bolusDoseExemptions.any((med) => medicament.contains(med));
      if (!exempted) {
        return error("wrongDose", "Bolus trop élevé : $dose ml");
      }
    }

    // C3. IM limites spécifiques
    if (administration == "im") {
      double limite = _imDoseLimits[medicament] ?? 3.0;
      if (dose > limite) {
        return error("wrongDose", "Dose IM trop élevée pour $medicament : $dose ml");
      }
    }

    // C4. Naloxone manquante en détresse respiratoire
    if (Fr < 8 && Sat < 90 && !medicament.contains("naloxone")) {
      return error("wrongDrug", "Naloxone requise (FR $Fr, SAT $Sat%)");
    }

    // ================================================================
    // D — ALERTES CLINIQUES (WARNING)
    // ================================================================

    if (Temp >= 38.0) {
      return warning("fièvre", "Fièvre détectée : $Temp °C");
    }

    if (Fc > 110 && Tas < 95 && Tas > 0) {
      return warning("clinicalAlert", "Signes de choc : FC $Fc bpm / TAS $Tas mmHg");
    }

    if (Sat > 0 && Sat < 92 && Fr >= 8) {
      return warning("hypoxie", "Saturation basse : $Sat%");
    }

    lastDose[idPatient] = dose;
    return ok();
  }

  Map<String, dynamic> ok() => {
        "status": "ok",
        "message": "Données normales",
        "patient": idPatient,
        "heure": heure
      };

  Map<String, dynamic> warning(String type, String msg) => {
        "status": "warning",
        "type": type,
        "message": msg,
        "patient": idPatient,
        "heure": heure
      };

  Map<String, dynamic> error(String type, String msg) => {
        "status": "error",
        "type": type,
        "message": msg,
        "patient": idPatient,
        "heure": heure
      };
}
