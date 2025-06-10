class PalmAnalysis {
  final String handType; // 'left' lub 'right'
  final HandShape handShape;
  final Fingers fingers;
  final PalmLines lines;
  final Mounts mounts;
  final SkinCharacteristics skin;
  final Nails paznokcie;
  final DateTime analysisDate;
  final String userName;

  PalmAnalysis({
    required this.handType,
    required this.handShape,
    required this.fingers,
    required this.lines,
    required this.mounts,
    required this.skin,
    required this.paznokcie,
    required this.analysisDate,
    required this.userName,
  });

  Map<String, dynamic> toJson() {
    return {
      'handType': handType,
      'handShape': handShape.toJson(),
      'fingers': fingers.toJson(),
      'lines': lines.toJson(),
      'mounts': mounts.toJson(),
      'skin': skin.toJson(),
      'paznokcie': paznokcie.toJson(),
      'analysisDate': analysisDate.toIso8601String(),
      'userName': userName,
    };
  }

  factory PalmAnalysis.fromJson(Map<String, dynamic> json) {
    return PalmAnalysis(
      handType: json['handType'],
      handShape: HandShape.fromJson(json['handShape']),
      fingers: Fingers.fromJson(json['fingers']),
      lines: PalmLines.fromJson(json['lines']),
      mounts: Mounts.fromJson(json['mounts']),
      skin: SkinCharacteristics.fromJson(json['skin']),
      paznokcie: Nails.fromJson(json['paznokcie']),
      analysisDate: DateTime.parse(json['analysisDate']),
      userName: json['userName'],
    );
  }

  // Konwertuj do promptu dla AI
  String toAIPrompt() {
    return '''
Analiza dłoni użytkownika: $userName
Typ ręki: ${handType == 'left' ? 'lewa' : 'prawa'}

KSZTAŁT DŁONI:
- Rozmiar: ${handShape.size}
- Forma: ${handShape.form}
- Typ elementu: ${handShape.elementType}

PALCE:
- Długość: ${fingers.length}
- Elastyczność: ${fingers.flexibility}
- Palec wskazujący: ${fingers.palecWskazujacy}
- Palec serdeczny: ${fingers.palecSerdeczny}
- Kciuk - typ: ${fingers.kciuk.typ}, ustawienie: ${fingers.kciuk.ustawienie}

LINIE:
- Linia życia: długość=${lines.lifeLine.dlugosc}, kształt=${lines.lifeLine.ksztalt}
- Linia głowy: długość=${lines.headLine.dlugosc}, kształt=${lines.headLine.ksztalt}
- Linia serca: długość=${lines.heartLine.dlugosc}, kształt=${lines.heartLine.ksztalt}
- Linia losu: obecność=${lines.fateLine.obecnosc}
- Linia słońca: obecność=${lines.sunLine.obecnosc}

WZGÓRKI:
- Jowisza: ${mounts.mountOfJupiter}
- Saturna: ${mounts.mountOfSaturne}
- Apollina: ${mounts.mountOfApollo}
- Merkurego: ${mounts.mountOfMercury}
- Wenus: ${mounts.mountOfVenus}

SKÓRA I PAZNOKCIE:
- Tekstura skóry: ${skin.tekstura}
- Kolor paznokci: ${paznokcie.kolor}

Na podstawie powyższej analizy dłoni, stwórz mistyczną, personalną interpretację dla użytkownika.
''';
  }
}

class HandShape {
  final String size;
  final String form;
  final String elementType;

  HandShape({
    required this.size,
    required this.form,
    required this.elementType,
  });

  Map<String, dynamic> toJson() => {
        'size': size,
        'form': form,
        'elementType': elementType,
      };

  factory HandShape.fromJson(Map<String, dynamic> json) => HandShape(
        size: json['size'],
        form: json['form'],
        elementType: json['elementType'],
      );
}

class Fingers {
  final String length;
  final String flexibility;
  final String palecWskazujacy;
  final String palecSerdeczny;
  final Thumb kciuk;

  Fingers({
    required this.length,
    required this.flexibility,
    required this.palecWskazujacy,
    required this.palecSerdeczny,
    required this.kciuk,
  });

  Map<String, dynamic> toJson() => {
        'length': length,
        'flexibility': flexibility,
        'palecWskazujacy': palecWskazujacy,
        'palecSerdeczny': palecSerdeczny,
        'kciuk': kciuk.toJson(),
      };

  factory Fingers.fromJson(Map<String, dynamic> json) => Fingers(
        length: json['length'],
        flexibility: json['flexibility'],
        palecWskazujacy: json['palecWskazujacy'],
        palecSerdeczny: json['palecSerdeczny'],
        kciuk: Thumb.fromJson(json['kciuk']),
      );
}

class Thumb {
  final String typ;
  final String ustawienie;

  Thumb({required this.typ, required this.ustawienie});

  Map<String, dynamic> toJson() => {'typ': typ, 'ustawienie': ustawienie};
  factory Thumb.fromJson(Map<String, dynamic> json) =>
      Thumb(typ: json['typ'], ustawienie: json['ustawienie']);
}

class PalmLines {
  final LifeLine lifeLine;
  final HeadLine headLine;
  final HeartLine heartLine;
  final FateLine fateLine;
  final SunLine sunLine;
  final HealthLine healthLine;
  final MarriageLines marriageLines;
  final ChildrenLines childrenLines;

  PalmLines({
    required this.lifeLine,
    required this.headLine,
    required this.heartLine,
    required this.fateLine,
    required this.sunLine,
    required this.healthLine,
    required this.marriageLines,
    required this.childrenLines,
  });

  Map<String, dynamic> toJson() => {
        'lifeLine': lifeLine.toJson(),
        'headLine': headLine.toJson(),
        'heartLine': heartLine.toJson(),
        'fateLine': fateLine.toJson(),
        'sunLine': sunLine.toJson(),
        'healthLine': healthLine.toJson(),
        'marriageLines': marriageLines.toJson(),
        'childrenLines': childrenLines.toJson(),
      };

  factory PalmLines.fromJson(Map<String, dynamic> json) => PalmLines(
        lifeLine: LifeLine.fromJson(json['lifeLine']),
        headLine: HeadLine.fromJson(json['headLine']),
        heartLine: HeartLine.fromJson(json['heartLine']),
        fateLine: FateLine.fromJson(json['fateLine']),
        sunLine: SunLine.fromJson(json['sunLine']),
        healthLine: HealthLine.fromJson(json['healthLine']),
        marriageLines: MarriageLines.fromJson(json['marriageLines']),
        childrenLines: ChildrenLines.fromJson(json['childrenLines']),
      );
}

class LifeLine {
  final String dlugosc;
  final String ksztalt;
  final String rozpoczecie;
  final String przebieg;

  LifeLine({
    required this.dlugosc,
    required this.ksztalt,
    required this.rozpoczecie,
    required this.przebieg,
  });

  Map<String, dynamic> toJson() => {
        'dlugosc': dlugosc,
        'ksztalt': ksztalt,
        'rozpoczecie': rozpoczecie,
        'przebieg': przebieg,
      };

  factory LifeLine.fromJson(Map<String, dynamic> json) => LifeLine(
        dlugosc: json['dlugosc'],
        ksztalt: json['ksztalt'],
        rozpoczecie: json['rozpoczecie'],
        przebieg: json['przebieg'],
      );
}

class HeadLine {
  final String dlugosc;
  final String ksztalt;
  final String rozpoczecie;
  final String koniec;

  HeadLine({
    required this.dlugosc,
    required this.ksztalt,
    required this.rozpoczecie,
    required this.koniec,
  });

  Map<String, dynamic> toJson() => {
        'dlugosc': dlugosc,
        'ksztalt': ksztalt,
        'rozpoczecie': rozpoczecie,
        'koniec': koniec,
      };

  factory HeadLine.fromJson(Map<String, dynamic> json) => HeadLine(
        dlugosc: json['dlugosc'],
        ksztalt: json['ksztalt'],
        rozpoczecie: json['rozpoczecie'],
        koniec: json['koniec'],
      );
}

class HeartLine {
  final String dlugosc;
  final String ksztalt;
  final String rozpoczecie;
  final String znaki;

  HeartLine({
    required this.dlugosc,
    required this.ksztalt,
    required this.rozpoczecie,
    required this.znaki,
  });

  Map<String, dynamic> toJson() => {
        'dlugosc': dlugosc,
        'ksztalt': ksztalt,
        'rozpoczecie': rozpoczecie,
        'znaki': znaki,
      };

  factory HeartLine.fromJson(Map<String, dynamic> json) => HeartLine(
        dlugosc: json['dlugosc'],
        ksztalt: json['ksztalt'],
        rozpoczecie: json['rozpoczecie'],
        znaki: json['znaki'],
      );
}

class FateLine {
  final String obecnosc;
  final String rozpoczecie;
  final String przebieg;

  FateLine({
    required this.obecnosc,
    required this.rozpoczecie,
    required this.przebieg,
  });

  Map<String, dynamic> toJson() => {
        'obecnosc': obecnosc,
        'rozpoczecie': rozpoczecie,
        'przebieg': przebieg,
      };

  factory FateLine.fromJson(Map<String, dynamic> json) => FateLine(
        obecnosc: json['obecnosc'],
        rozpoczecie: json['rozpoczecie'],
        przebieg: json['przebieg'],
      );
}

class SunLine {
  final String obecnosc;
  final String rozpoczecie;
  final String przebieg;

  SunLine({
    required this.obecnosc,
    required this.rozpoczecie,
    required this.przebieg,
  });

  Map<String, dynamic> toJson() => {
        'obecnosc': obecnosc,
        'rozpoczecie': rozpoczecie,
        'przebieg': przebieg,
      };

  factory SunLine.fromJson(Map<String, dynamic> json) => SunLine(
        obecnosc: json['obecnosc'],
        rozpoczecie: json['rozpoczecie'],
        przebieg: json['przebieg'],
      );
}

class HealthLine {
  final String obecnosc;
  final String przebieg;

  HealthLine({required this.obecnosc, required this.przebieg});

  Map<String, dynamic> toJson() => {'obecnosc': obecnosc, 'przebieg': przebieg};
  factory HealthLine.fromJson(Map<String, dynamic> json) =>
      HealthLine(obecnosc: json['obecnosc'], przebieg: json['przebieg']);
}

class MarriageLines {
  final String ilosc;
  final String ksztalt;
  final String znaki;

  MarriageLines({
    required this.ilosc,
    required this.ksztalt,
    required this.znaki,
  });

  Map<String, dynamic> toJson() => {
        'ilosc': ilosc,
        'ksztalt': ksztalt,
        'znaki': znaki,
      };

  factory MarriageLines.fromJson(Map<String, dynamic> json) => MarriageLines(
        ilosc: json['ilosc'],
        ksztalt: json['ksztalt'],
        znaki: json['znaki'],
      );
}

class ChildrenLines {
  final String ilosc;
  final String intensywnosc;

  ChildrenLines({required this.ilosc, required this.intensywnosc});

  Map<String, dynamic> toJson() => {
        'ilosc': ilosc,
        'intensywnosc': intensywnosc,
      };
  factory ChildrenLines.fromJson(Map<String, dynamic> json) =>
      ChildrenLines(ilosc: json['ilosc'], intensywnosc: json['intensywnosc']);
}

class Mounts {
  final String mountOfJupiter;
  final String mountOfSaturne;
  final String mountOfApollo;
  final String mountOfMercury;
  final String mountOfVenus;
  final String mountOfMarsUpper;
  final String mountOfMarsLower;
  final String mountOfMoon;

  Mounts({
    required this.mountOfJupiter,
    required this.mountOfSaturne,
    required this.mountOfApollo,
    required this.mountOfMercury,
    required this.mountOfVenus,
    required this.mountOfMarsUpper,
    required this.mountOfMarsLower,
    required this.mountOfMoon,
  });

  Map<String, dynamic> toJson() => {
        'mountOfJupiter': mountOfJupiter,
        'mountOfSaturne': mountOfSaturne,
        'mountOfApollo': mountOfApollo,
        'mountOfMercury': mountOfMercury,
        'mountOfVenus': mountOfVenus,
        'mountOfMarsUpper': mountOfMarsUpper,
        'mountOfMarsLower': mountOfMarsLower,
        'mountOfMoon': mountOfMoon,
      };

  factory Mounts.fromJson(Map<String, dynamic> json) => Mounts(
        mountOfJupiter: json['mountOfJupiter'],
        mountOfSaturne: json['mountOfSaturne'],
        mountOfApollo: json['mountOfApollo'],
        mountOfMercury: json['mountOfMercury'],
        mountOfVenus: json['mountOfVenus'],
        mountOfMarsUpper: json['mountOfMarsUpper'],
        mountOfMarsLower: json['mountOfMarsLower'],
        mountOfMoon: json['mountOfMoon'],
      );
}

class SkinCharacteristics {
  final String tekstura;
  final String wilgotnosc;
  final String kolor;

  SkinCharacteristics({
    required this.tekstura,
    required this.wilgotnosc,
    required this.kolor,
  });

  Map<String, dynamic> toJson() => {
        'tekstura': tekstura,
        'wilgotnosc': wilgotnosc,
        'kolor': kolor,
      };

  factory SkinCharacteristics.fromJson(Map<String, dynamic> json) =>
      SkinCharacteristics(
        tekstura: json['tekstura'],
        wilgotnosc: json['wilgotnosc'],
        kolor: json['kolor'],
      );
}

class Nails {
  final String dlugosc;
  final String ksztalt;
  final String kolor;

  Nails({required this.dlugosc, required this.ksztalt, required this.kolor});

  Map<String, dynamic> toJson() => {
        'dlugosc': dlugosc,
        'ksztalt': ksztalt,
        'kolor': kolor,
      };

  factory Nails.fromJson(Map<String, dynamic> json) => Nails(
        dlugosc: json['dlugosc'],
        ksztalt: json['ksztalt'],
        kolor: json['kolor'],
      );
}
