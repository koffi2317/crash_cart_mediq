class Detector {
  // signes vitaux
  int Fr;
  int Sat;
  int Fc;
  int Tas;
  int Tad;
  int Temp;

  // medication variables
  double dose;
  double concentration;
  String administration;
  String medicament;

  // patient
  int idPatient;
  String heure;

  Map<int, double> lastDose = {};

  void analyser(row) {

Fr = row.fr;
Sat = row.sat;
Fc = row.fc;
Tas = row.tas;
Tad = row.tad;
Temp = row.temp;
dose = row.dose;
concentration = row.concentration;
administration = row.administration;
medicament = row.medicament;
idPatient = row.idPatient;
heure = row.heure;

    //  Perfusion =toujours OK
    if (administration == "Perfusion") {
      print("ok");
      lastDose[idPatient] = dose;
      return;
    }

    //  Mauvais médicament
    if (Fr < 8 && Sat < 90 && medicament != "Naloxone") {
      return isWrongDrug(row);
    }

    //  Bolus trop grand
    if (administration == "Bolus" && dose > 5) {
      return isWrongDose(row);
    }

    //  IM trop grand
    if (administration == "IM" && dose > 3) {
      return isWrongDose(row);
    }

    //  Dose totale incohérente
    if ((dose * concentration) > 100 || (dose * concentration) < 0.1) {
      return isWrongDose(row);
    }

    //  Dose très différente de la précédente
    if (lastDose.containsKey(idPatient) &&
        (dose > lastDose[idPatient]! * 5 || dose < lastDose[idPatient]! / 5)) {
      return isWrongDose(row);
    }

    //  Mauvaise administration
    if (administration == "IM" && concentration > 50) {
      return isWrongAdministration(row);
    }

    if (administration == "Bolus" && concentration < 0.1) {
      return isWrongAdministration(row);
    }

    if (administration == "Bolus" && dose > 10) {
      return isWrongAdministration(row);
    }

    if (administration == "IM" && dose > 5) {
      return isWrongAdministration(row);
    }

    //  Incohérence vitale
    if (Fr < 5 && Sat > 95) {
      return isIllogicalForVitals(row);
    }

    if (Fc < 20 || Fc > 220) {
      return isIllogicalForVitals(row);
    }

    if (Tas < 60 || Tas > 220) {
      return isIllogicalForVitals(row);
    }

    if (Tas < 80 && Fc < 40) {
      return isIllogicalForVitals(row);
    }

    //  OK final
    print("ok");
    lastDose[idPatient] = dose;
    return;
  }

  Map<String, dynamic> isWrongDrug(row) {
    print("ERREUR : mauvais médicament");
    return {
      "status": "error",
      "type": "wrongDrug",
      "message": "Mauvais médicament",
      "patient": idPatient,
      "heure": heure
    };
  }

  Map<String, dynamic> isWrongDose(row) {
    return {
    "status": "error",
    "type": "wrongDose",
    "message": "Dose incorrecte",
    "patient": idPatient,
    "heure": heure
  };
  }

  Map<String, dynamic> isWrongAdministration(row) {
    
    return {
      "status": "error",
      "type": "wrongAdministration",
      "message": "Voie d'administration incorrecte",
      "patient": idPatient,
      "heure": heure
    };
  }

  Map<String, dynamic> isIllogicalForVitals(row) {
    return {
      "status": "error",
      "type": "illogicalForVitals",
      "message": "Incohérence avec les signes vitaux",
      "patient": idPatient,
      "heure": heure
    };
  }
}
