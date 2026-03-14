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

    //  Perfusion = toujours OK
    if (administration == "Perfusion") {
      lastDose[idPatient] = dose;
      return ok();
    }

    //  Mauvais médicament (Surdose Opioïdes)
    if (Fr < 8 && Sat < 90 && medicament != "Naloxone") {
      return error("wrongDrug", "Mauvais médicament (Attendu: Naloxone)");
    }

    //  Dose critique Bolus/IM
    if (administration == "Bolus" && dose > 5) return error("wrongDose", "Bolus trop grand");
    if (administration == "IM" && dose > 3) return error("wrongDose", "IM trop grand");

    //  Incohérence Dose Totale
    if ((dose * concentration) > 100 || (dose * concentration) < 0.1) {
      return error("wrongDose", "Dose totale incohérente");
    }

    //  Incohérence Vitale 
    if (Fr < 5 && Sat > 95) return error("illogicalVitals", "Signes vitaux contradictoires");
    if (Fc < 20 || Fc > 220) return error("illogicalVitals", "Fréquence cardiaque impossible");

    lastDose[idPatient] = dose;
    return ok();
  }

  Map<String, dynamic> ok() {
    return {"status": "ok", "message": "OK", "patient": idPatient, "heure": heure};
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