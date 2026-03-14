import 'models.dart';

class Detector {
  // Variables de session pour les calculs
  late int Fr, Sat, Fc, Tas, Tad, idPatient;
  late double Temp, dose, concentration, volumePerfusion;
  late String administration, medicament, heure;

  Map<int, double> lastDose = {};

  // ---------------------------------------------------------------
  // Liste blanche : médicaments dont la dose Bolus peut dépasser 5ml
  // Ces volumes sont normaux en contexte d'urgence / réanimation
  // ---------------------------------------------------------------
  static const Set<String> _bolusDoseExemptions = {
    "Dextrose",
    "Bicarbonnate de sodium",
    "Bicarbonate de sodium",
    "Chlorure de calcium",
    "Soluté physiologique",
    "Albumine",
    "Mannitol",
    "Magnésium",
    "Potassium",
  };

  // ---------------------------------------------------------------
  // Seuils de dose IM par médicament (ml)
  // Valeur par défaut si non listé : 3ml
  // ---------------------------------------------------------------
  static const Map<String, double> _imDoseLimits = {
    "Épinéphrine": 0.5,   // Épi IM anaphylaxie = 0.3–0.5ml (1mg/ml)
    "Atropine": 1.0,
  };

  Map<String, dynamic> analyser(LigneData row) {
    // 1. Conversion et sécurisation des données
    Fr  = int.tryParse(row.fr.toString())  ?? 0;
    Sat = int.tryParse(row.sat.toString()) ?? 0;
    Fc  = int.tryParse(row.fc.toString())  ?? 0;
    Tas = int.tryParse(row.tas.toString()) ?? 0;
    Tad = int.tryParse(row.tad.toString()) ?? 0;
    Temp            = double.tryParse(row.temp.toString())             ?? 0.0;
    dose            = row.dose;
    concentration   = row.concentration;
    volumePerfusion = row.volumePerfusion;
    administration  = row.administration;
    medicament      = row.medicament;
    idPatient       = int.tryParse(row.idPatient.toString()) ?? 0;
    heure           = row.heure;

    // ================================================================
    //  BLOC A — COHÉRENCE DES DONNÉES
    // ================================================================

    // A1. Concentration présente sans volume de perfusion (perfusion seulement)
    if (administration == "Perfusion" && concentration > 0 && volumePerfusion <= 0) {
      return error("illogicalData",
          "Concentration présente sans volume de perfusion ($medicament)");
    }

    // ================================================================
    //  BLOC B — SIGNES VITAUX : VALEURS IMPOSSIBLES
    //  À vérifier EN PREMIER pour ne pas analyser des données corrompues
    // ================================================================

    // B1. Tension impossible (TAS ≤ TAD)
    if (Tas > 0 && Tad > 0 && Tas <= Tad) {
      return error("illogicalVitals",
          "Tension impossible : TAS $Tas mmHg ≤ TAD $Tad mmHg");
    }

    // B2. Fréquence cardiaque hors limites humaines
    if (Fc > 0 && (Fc < 20 || Fc > 220)) {
      return error("illogicalVitals",
          "FC hors limites humaines ($Fc bpm)");
    }

    // B3. Température non physiologique
    if (Temp > 0 && (Temp > 42.0 || Temp < 30.0)) {
      return error("illogicalVitals",
          "Température non physiologique ($Temp °C)");
    }

    // B4. Incohérence FR très basse + SAT normale
    if (Fr > 0 && Sat > 0 && Fr < 5 && Sat > 95) {
      return error("illogicalVitals",
          "Incohérence : FR très basse ($Fr /min) avec SAT normale ($Sat %)");
    }

    // ================================================================
    //  BLOC C — URGENCES VITALES (état critique du patient)
    //  Priorité haute : à évaluer avant les règles médicamenteuses
    // ================================================================

    // C1. Dépression respiratoire → Naloxone attendue
    if (Fr < 8 && Sat < 90 && medicament != "Naloxone") {
      return error("wrongDrug",
          "Urgence respiratoire : Naloxone attendue (FR $Fr /min, SAT $Sat %)");
    }

    // C2. Arrêt cardiaque / bradycardie sévère avec hypotension
    //     Seuil abaissé : FC < 50 ET TAS < 90 pour couvrir le choc
    if (Fc > 0 && Tas > 0 && Fc < 50 && Tas < 90) {
      return error("illogicalVitals",
          "Bradycardie sévère avec hypotension : FC $Fc bpm, TAS $Tas mmHg");
    }

    // C3. Choc : tachycardie + hypotension
    //     Seuil abaissé : FC > 100 ET TAS < 90 (plus sensible)
    if (Fc > 100 && Tas < 90) {
      return error("illogicalVitals",
          "Tableau de choc : FC $Fc bpm avec TAS $Tas mmHg");
    }

    // ================================================================
    //  BLOC D — SÉCURITÉ MÉDICAMENTEUSE
    // ================================================================

    // D1. Dose Bolus excessive
    //     Exception : certains médicaments de réanimation dépassent légitimement 5ml
    if (administration == "Bolus" && dose > 5) {
      bool exempted = _bolusDoseExemptions.any(
          (med) => medicament.toLowerCase().contains(med.toLowerCase()));
      if (!exempted) {
        return error("wrongDose",
            "Dose Bolus trop élevée pour $medicament : $dose ml (max 5 ml)");
      }
    }

    // D2. Dose IM excessive (seuil spécifique par médicament ou 3ml par défaut)
    if (administration == "IM" && dose > 0) {
      double limiteIM = _imDoseLimits[medicament] ?? 3.0;
      if (dose > limiteIM) {
        return error("wrongDose",
            "Dose IM trop élevée pour $medicament : $dose ml (max $limiteIM ml)");
      }
    }

    // ================================================================
    //  BLOC E — AVERTISSEMENTS (signes préoccupants non critiques)
    // ================================================================

    // E1. Hypotension isolée
    if (Tas > 0 && Tas < 90) {
      return warning("hypotension",
          "Hypotension : TAS $Tas mmHg — surveiller l'état hémodynamique");
    }

    // E2. Fièvre
    if (Temp >= 38.0) {
      return warning("fièvre",
          "Patient fébrile : $Temp °C");
    }

    // E3. Saturation basse (sans FR basse, sinon déjà attrapé en C1)
    if (Sat > 0 && Sat < 90) {
      return warning("hypoxie",
          "Saturation basse : $Sat % — évaluer la détresse respiratoire");
    }

    // E4. Tachycardie modérée sans hypotension
    if (Fc > 100 && Tas >= 90) {
      return warning("tachycardie",
          "Tachycardie : FC $Fc bpm — surveiller l'évolution");
    }

    // ================================================================
    //  TOUT EST OK
    // ================================================================
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
      "status": "warning",
      "type": type,
      "message": msg,
      "patient": idPatient,
      "heure": heure
    };
  }

  Map<String, dynamic> error(String type, String msg) {
    return {
      "status": "error",
      "type": type,
      "message": msg,
      "patient": idPatient,
      "heure": heure
    };
  }
}