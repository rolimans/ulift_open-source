import 'package:firebase_crashlytics/firebase_crashlytics.dart';

class Usuario {
  String uid;
  String number;
  String mat;
  String nome;
  DateTime birth;
  String sex;
  int tipo;
  String picUrl;
  bool onGoingRequest;
  Map playerIds;
  double ratingDriver;
  double ratingRider;
  int numberOfDrived;
  int numberOfRided;
  String level;

  Usuario(
      {this.number,
      this.mat,
      this.nome,
      this.birth,
      this.sex,
      this.tipo,
      this.playerIds,
      this.onGoingRequest,
      this.ratingDriver,
      this.ratingRider,
      this.numberOfDrived,
      this.numberOfRided,
      this.level});

  Usuario.fromJson(Map<String, dynamic> json) {
    number = json['number'];
    mat = json['mat'];
    nome = json['nome'];
    sex = json['sex'];
    picUrl = json['picUrl'];
    tipo = json['tipo']?.toInt();
    level = json['level'];
    if (json['birth'] != null) {
      birth = DateTime.fromMillisecondsSinceEpoch(json['birth']?.toInt());
    }
    onGoingRequest = json['onGoingRequest'];
    ratingDriver = json['ratingDriver']?.toDouble();
    ratingRider = json["ratingRider"]?.toDouble();
    numberOfDrived = json["numberOfDrived"]?.toInt();
    numberOfRided = json["numberOfRided"]?.toInt();
  }

  Map<String, dynamic> toJson() => {
        'nome': nome,
        'mat': mat,
        'number': number,
        'birth': birth?.millisecondsSinceEpoch,
        'sex': sex,
        'picUrl': picUrl,
        'tipo': tipo,
        'level': level,
        'onGoingRequest': onGoingRequest,
        "ratingDriver": ratingDriver,
        "ratingRider": ratingRider,
        "numberOfRided": numberOfRided,
        "numberOfDrived": numberOfDrived
      };

  get levelFormatted {
    switch (this.level) {
      case "A":
        return "Alunos";
      case "S":
        return "Servidores";
      default:
        Crashlytics.instance.log("ERROR IN LEVEL FORMATTING");
        return "Alunos";
    }
  }

  get genderFormatted {
    switch (this.sex) {
      case "M":
        return "Homens";
      case "F":
        return "Mulheres";
      default:
        Crashlytics.instance.log("ERROR IN TYPO FORMATTING");
        return "Mulheres";
    }
  }

  bool fitsGender(String g) {
    return (g == "Todos" || g == this.genderFormatted);
  }

  bool fitsLevel(String l) {
    return (l == "Todos" || l == this.levelFormatted);
  }
}
