/// Método biométrico preferido por el usuario.
enum BioMethod { fingerprint, face }

extension BioMethodX on BioMethod {
  String get key => name;
  String get label => this == BioMethod.face ? 'rostro' : 'huella';
  String get title => this == BioMethod.face ? 'Reconocimiento facial' : 'Huella dactilar';
}

BioMethod bioMethodFromKey(String? key) =>
    key == BioMethod.face.name ? BioMethod.face : BioMethod.fingerprint;
