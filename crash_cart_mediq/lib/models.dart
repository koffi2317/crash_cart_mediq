class LigneData {
  final dynamic idPatient;
  final String heure;
  final dynamic fc;
  final dynamic tas;
  final dynamic tad;
  final dynamic fr;
  final dynamic sat;
  final dynamic temp;
  final String medicament;
  final double dose;
  final double concentration;
  final String administration;
  final double volumePerfusion; 

  LigneData({
    required this.idPatient,
    required this.heure,
    required this.fc,
    required this.tas,
    required this.tad,
    required this.fr,
    required this.sat,
    required this.temp,
    required this.medicament,
    required this.dose,
    required this.concentration,
    required this.administration,
    required this.volumePerfusion, 
  });
}