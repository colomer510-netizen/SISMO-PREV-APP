// ============================================================================
// SismoGuard — Constantes y Enums del Protocolo de Alerta Común (CAP 1.2)
// ============================================================================
// Referencia: OASIS CAP v1.2 — urn:oasis:names:tc:emergency:cap:1.2
// Documentación: http://docs.oasis-open.org/emergency/cap/v1.2/CAP-v1.2-os.html
// ============================================================================

/// Namespace XML del protocolo CAP 1.2.
const String capNamespace = 'urn:oasis:names:tc:emergency:cap:1.2';

/// Estado del mensaje de alerta CAP.
///
/// Determina si el mensaje es real, un ejercicio, o de prueba técnica.
enum CapStatus {
  /// Alerta real. Activar protocolo de emergencia completo.
  actual('Actual'),

  /// Simulacro o ejercicio. Mostrar modo seguro con "SIMULACRO EN CURSO".
  exercise('Exercise'),

  /// Mensaje de sistema. Solo para procesamiento interno.
  system('System'),

  /// Mensaje de prueba técnica. Solo logging, sin alerta al usuario.
  test('Test'),

  /// Borrador. No debe ser procesado ni mostrado.
  draft('Draft');

  const CapStatus(this.xmlValue);
  final String xmlValue;

  /// Parsea un string XML al enum correspondiente.
  static CapStatus fromXml(String value) {
    return CapStatus.values.firstWhere(
      (e) => e.xmlValue.toLowerCase() == value.toLowerCase(),
      orElse: () => CapStatus.actual, // Fail-safe: tratar como real
    );
  }
}

/// Tipo de mensaje CAP.
enum CapMsgType {
  alert('Alert'),
  update('Update'),
  cancel('Cancel'),
  ack('Ack'),
  error('Error');

  const CapMsgType(this.xmlValue);
  final String xmlValue;

  static CapMsgType fromXml(String value) {
    return CapMsgType.values.firstWhere(
      (e) => e.xmlValue.toLowerCase() == value.toLowerCase(),
      orElse: () => CapMsgType.alert,
    );
  }
}

/// Alcance del mensaje CAP.
enum CapScope {
  public('Public'),
  restricted('Restricted'),
  private_('Private');

  const CapScope(this.xmlValue);
  final String xmlValue;

  static CapScope fromXml(String value) {
    return CapScope.values.firstWhere(
      (e) => e.xmlValue.toLowerCase() == value.toLowerCase(),
      orElse: () => CapScope.public,
    );
  }
}

/// Categoría del evento de alerta.
enum CapCategory {
  geo('Geo'),       // Geofísico (terremotos, erupciones volcánicas)
  met('Met'),       // Meteorológico
  safety('Safety'), // Seguridad pública
  security('Security'),
  rescue('Rescue'),
  fire('Fire'),
  health('Health'),
  env('Env'),       // Medioambiental
  transport('Transport'),
  infra('Infra'),   // Infraestructura
  cbrne('CBRNE'),   // Químico, Biológico, Radiológico, Nuclear, Explosivo
  other('Other');

  const CapCategory(this.xmlValue);
  final String xmlValue;

  static CapCategory fromXml(String value) {
    return CapCategory.values.firstWhere(
      (e) => e.xmlValue.toLowerCase() == value.toLowerCase(),
      orElse: () => CapCategory.other,
    );
  }
}

/// Urgencia de la acción requerida.
///
/// Refleja el marco temporal para la respuesta.
enum CapUrgency {
  /// Acción inmediata requerida. Máxima prioridad.
  immediate('Immediate', 4),

  /// Acción esperada en un futuro cercano.
  expected('Expected', 3),

  /// Acción puede ser necesaria en el futuro.
  future('Future', 2),

  /// Evento ya pasado. Solo informativo.
  past('Past', 1),

  /// Urgencia desconocida.
  unknown('Unknown', 0);

  const CapUrgency(this.xmlValue, this.numericLevel);
  final String xmlValue;
  final int numericLevel;

  static CapUrgency fromXml(String value) {
    return CapUrgency.values.firstWhere(
      (e) => e.xmlValue.toLowerCase() == value.toLowerCase(),
      orElse: () => CapUrgency.unknown,
    );
  }
}

/// Severidad del evento.
///
/// Refleja el nivel de amenaza a la vida o propiedad.
enum CapSeverity {
  /// Amenaza extraordinaria a la vida o propiedad.
  extreme('Extreme', 4),

  /// Amenaza significativa a la vida o propiedad.
  severe('Severe', 3),

  /// Posibles amenazas a la vida o propiedad.
  moderate('Moderate', 2),

  /// Impacto mínimo esperado.
  minor('Minor', 1),

  /// Severidad desconocida.
  unknown('Unknown', 0);

  const CapSeverity(this.xmlValue, this.numericLevel);
  final String xmlValue;
  final int numericLevel;

  static CapSeverity fromXml(String value) {
    return CapSeverity.values.firstWhere(
      (e) => e.xmlValue.toLowerCase() == value.toLowerCase(),
      orElse: () => CapSeverity.unknown,
    );
  }
}

/// Certeza del evento.
///
/// Refleja la probabilidad de que el evento ocurra.
enum CapCertainty {
  /// Evento observado directamente. Confirmado.
  observed('Observed', 4),

  /// Probabilidad > 50%.
  likely('Likely', 3),

  /// Probabilidad < 50%.
  possible('Possible', 2),

  /// No se espera que ocurra.
  unlikely('Unlikely', 1),

  /// Certeza desconocida.
  unknown('Unknown', 0);

  const CapCertainty(this.xmlValue, this.numericLevel);
  final String xmlValue;
  final int numericLevel;

  static CapCertainty fromXml(String value) {
    return CapCertainty.values.firstWhere(
      (e) => e.xmlValue.toLowerCase() == value.toLowerCase(),
      orElse: () => CapCertainty.unknown,
    );
  }
}

/// Tipo de respuesta sugerida por la alerta CAP.
enum CapResponseType {
  shelter('Shelter'),
  evacuate('Evacuate'),
  prepare('Prepare'),
  execute('Execute'),
  avoid('Avoid'),
  monitor('Monitor'),
  assess('Assess'),
  allClear('AllClear'),
  none('None');

  const CapResponseType(this.xmlValue);
  final String xmlValue;

  static CapResponseType fromXml(String value) {
    return CapResponseType.values.firstWhere(
      (e) => e.xmlValue.toLowerCase() == value.toLowerCase(),
      orElse: () => CapResponseType.none,
    );
  }
}
