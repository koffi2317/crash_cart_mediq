import 'models.dart';

class Detector {
  late int Fr, Sat, Fc, Tas, Tad, Temp, idPatient;
  late double dose, concentration;
  late String administration, medicament, heure;

  Map<int, double> lastDose = {};

  Map<String, dynamic> analyser(LigneData row) {
    // Conversion et sécurisation des données
    Fr = int.tryParse(row.fr.toString()) ?? 0;
    Sat = int.tryParse(row.sat.toString()) ?? 0;
    Fc = int.tryParse(row.fc.toString()) ?? 0;
    Tas = int.tryParse(row.tas.toString()) ?? 0;
    Tad = int.tryParse(row.tad.toString()) ?? 0;
    Temp = int.tryParse(row.temp.toString()) ?? 0;
    dose = row.dose;
    concentration = row.concentration;
    administration = row.administration;
    medicament = row.medicament;
    idPatient = int.tryParse(row.idPatient.toString()) ?? 0;
    heure = row.heure;

    // 1. Perfusion = toujours OK
    if (administration == "Perfusion") {
      lastDose[idPatient] = dose;
      return ok();
    }

    // 2. Mauvais médicament (dépression respiratoire)
    if (Fr < 8 && Sat < 90 && medicament != "Naloxone") {
      return error("wrongDrug", "Mauvais médicament (Attendu: Naloxone)");
    }

    // 3. Dose critique Bolus/IM
    if (administration == "Bolus" && dose > 5) {
      return error("wrongDose", "Bolus trop grand");
    }
    if (administration == "IM" && dose > 3) {
      return error("wrongDose", "IM trop grand");
    }

    // 4. Incohérence Dose Totale
    if ((dose * concentration) > 100 || (dose * concentration) < 0.1) {
      return error("wrongDose", "Dose totale incohérente");
    }

    // -----------------------------
    // 🔥 NOUVELLES RÈGLES LOGIQUES
    // -----------------------------

    // 5. TA incohérente
    if (Tas < Tad) {
      return error("illogicalVitals", "Tension impossible (TAS < TAD)");
    }
    if (Tas < 50 || Tas > 250) {
      return error("illogicalVitals", "Tension systolique incohérente");
    }
    if (Tad < 30 || Tad > 150) {
      return error("illogicalVitals", "Tension diastolique incohérente");
    }

    // 6. Température incohérente
    if (Temp < 30 || Temp > 42) {
      return error("illogicalVitals", "Température non physiologique");
    }

    // 7. Relation FC ↔ TA
    if (Fc > 150 && Tas < 80) {
      return error("illogicalVitals", "FC élevée avec TA basse");
    }
    if (Fc < 40 && Tas < 80) {
      return error("illogicalVitals", "Bradycardie avec hypotension");
    }

    // 8. Relation FR ↔ SAT
    if (Fr > 30 && Sat < 85) {
      return error("illogicalVitals", "FR élevée avec saturation basse");
    }

    // 9. Signes vitaux impossibles (déjà existants)
    if (Fr < 5 && Sat > 95) {
      return error("illogicalVitals", "Signes vitaux contradictoires");
    }
    if (Fc < 20 || Fc > 220) {
      return error("illogicalVitals", "Fréquence cardiaque impossible");
    }

    // 10. Mise à jour dose précédente
    lastDose[idPatient] = dose;

    return ok();
  }

  Map<String, dynamic> ok() {
    return {
      "status": "ok",
      "message": "OK",
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
