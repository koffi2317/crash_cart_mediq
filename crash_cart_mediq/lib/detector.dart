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
double consentration;
String administration;
String medicament;
//variable juste [pour le moment] pour identifier le patient
int idPatient; 
String heure;

void analyser(row){

if(administration=="Perfusion"){
  print("ok");


}

else if ( Fr<8 && Sat<90 && medicament != "Naloxone"){ 

return isWrongDrug(row);

}

else if (administration=="bolus" && dose>0.5||  ){ 


  return isWrongDose(row);
}


else if (){
  return isWrongAdministration(row);
}

else if (){ 

  return isIllogicalForVitals(row);

}


else { 
  print("ok");
}

}




void isWrongDrug(row){

}

void isWrongDose(row){

}

void isWrongAdministration(row){

}

void isIllogicalForVitals(row){}






}
