class Detector {
//signes vitaux;
int Fr;
int Sat;
int Fc; 
int Tas; 
int Tad;

int Temp;
//medication variables
double dose; 
double concentration;
String administration;
String medicament;
//variable juste [pour le moment] pour identifier le patient
int idPatient; 
String heure;

Map<int, double> lastDose = {};




void analyser(row){

if(administration=="Perfusion"){
  print("ok");
  lastDose[idPatient] = dose;
  return;


}

else if ( Fr<8 && Sat<90 && medicament != "Naloxone"){ 

return isWrongDrug(row);

}

// 1) Bolus trop grand
else if (administration == "Bolus" && dose > 5) {
  return isWrongDose(row);
}

// 2) IM trop grand
else if (administration == "IM" && dose > 3) {
  return isWrongDose(row);
}

// 3) Dose totale incohérente (dose * concentration)
else if ((dose * concentration) > 100 || (dose * concentration) < 0.1) {
  return isWrongDose(row);
}

// 4) Dose très différente de la précédente
else if (lastDose.containsKey(idPatient) &&
        (dose > lastDose[idPatient]! * 5 || dose < lastDose[idPatient]! / 5)) {
 {
  return isWrongDose(row);
 } 

        }


else if (administration == "IM" && concentration > 50) {
    return isWrongAdministration(row);
  }

  //  Médicament très dilué donné en bolus → suspect
  else if (administration == "Bolus" && concentration < 0.1) {
    return isWrongAdministration(row);
  }

  //  Volume incohérent pour la voie (sécurité supplémentaire)
  else if (administration == "Bolus" && dose > 10) {
    return isWrongAdministration(row);
  }
  else if (administration == "IM" && dose > 5) {
    return isWrongAdministration(row);
  }

else if (Fr < 5 && Sat > 95) {
    return isIllogicalForVitals(row);
  }

  //  Valeurs extrêmes
  else if (Fc < 20 || Fc > 220) {
    return isIllogicalForVitals(row);
  }
  else if (Tas < 60 || Tas > 220) {
    return isIllogicalForVitals(row);
  }

  //  Tension très basse + FC très basse → incohérent
  else if (Tas < 80 && Fc < 40) {
    return isIllogicalForVitals(row);
  }



   print("ok");
lastDose[idPatient] = dose;
return;
}




void isWrongDrug(row){
print("ERREUR : mauvais médicament");
}

void isWrongDose(row){
print("ERREUR : dose incorrecte");
}

void isWrongAdministration(row){
print("ERREUR : voie d'administration incorrecte");
}

void isIllogicalForVitals(row){
print("ERREUR : incohérence avec les signes vitaux");
}






}
