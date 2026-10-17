// ============================================================================
// SismoGuard — Entidad: Alerta CAP 1.2
// ============================================================================
// Modelo de dominio que representa un mensaje de alerta bajo el
// Protocolo de Alerta Común (Common Alerting Protocol) versión 1.2.
//
// Referencia: OASIS CAP v1.2 — urn:oasis:names:tc:emergency:cap:1.2
// http://docs.oasis-open.org/emergency/cap/v1.2/CAP-v1.2-os.html
// ============================================================================

import 'package:equatable/equatable.dart';

import '../../../../core/constants/cap_constants.dart';

/// Bloque <info> de un mensaje CAP.
///
/// Un mensaje CAP puede contener múltiples bloques <info>,
/// cada uno para un idioma o audiencia diferente.
class CapAlertInfo extends Equatable {
  const CapAlertInfo({
    this.language = 'es',
    required this.category,
    required this.event,
    required this.urgency,
    required this.severity,
    required this.certainty,
    this.responseTypes = const [],
    this.audience,
    this.effectiveDate,
    this.expiresDate,
    this.senderName,
    this.headline,
    this.description,
    this.instruction,
    this.contact,
    this.areas = const [],
  });

  /// Idioma del bloque info (ej. "es", "en-US").
  final String language;

  /// Categoría del evento (Geo, Met, Safety, etc.).
  final CapCategory category;

  /// Nombre del evento (ej. "Terremoto", "Tsunami").
  final String event;

  /// Urgencia de la acción requerida.
  final CapUrgency urgency;

  /// Severidad del evento.
  final CapSeverity severity;

  /// Certeza / probabilidad del evento.
  final CapCertainty certainty;

  /// Tipos de respuesta recomendados.
  final List<CapResponseType> responseTypes;

  /// Audiencia objetivo.
  final String? audience;

  /// Fecha y hora efectiva de la alerta.
  final DateTime? effectiveDate;

  /// Fecha y hora de expiración.
  final DateTime? expiresDate;

  /// Nombre del emisor.
  final String? senderName;

  /// Titular corto de la alerta.
  final String? headline;

  /// Descripción detallada del evento.
  final String? description;

  /// Instrucciones de acción para la población.
  final String? instruction;

  /// Información de contacto.
  final String? contact;

  /// Áreas geográficas afectadas.
  final List<CapArea> areas;

  /// Calcula el nivel de prioridad numérico compuesto.
  /// Rango: 0 (mínimo) a 12 (máximo = Immediate + Extreme + Observed).
  int get priorityScore =>
      urgency.numericLevel + severity.numericLevel + certainty.numericLevel;

  /// Indica si esta alerta requiere acción inmediata.
  bool get requiresImmediateAction =>
      urgency == CapUrgency.immediate && severity.numericLevel >= 3;

  @override
  List<Object?> get props => [
        language, category, event, urgency, severity, certainty,
        responseTypes, headline, description, instruction,
      ];
}

/// Área geográfica afectada por una alerta CAP.
class CapArea extends Equatable {
  const CapArea({
    required this.description,
    this.polygons = const [],
    this.circles = const [],
    this.geocodes = const {},
    this.altitude,
    this.ceiling,
  });

  /// Descripción textual del área (ej. "Provincia de San José").
  final String description;

  /// Polígonos que definen el área (lista de pares lat,lon).
  final List<String> polygons;

  /// Círculos (centro + radio).
  final List<String> circles;

  /// Códigos geográficos (ej. FIPS, UGC).
  final Map<String, String> geocodes;

  /// Altitud mínima (metros sobre nivel del mar).
  final double? altitude;

  /// Altitud máxima (techo).
  final double? ceiling;

  @override
  List<Object?> get props => [description, polygons, circles, geocodes];
}

/// Mensaje de alerta CAP 1.2 completo.
///
/// Estructura jerárquica:
/// <alert>
///   ├── <identifier>
///   ├── <sender>
///   ├── <sent>
///   ├── <status>     → CapStatus (Actual, Exercise, Test, etc.)
///   ├── <msgType>    → CapMsgType (Alert, Update, Cancel, etc.)
///   ├── <scope>      → CapScope (Public, Restricted, Private)
///   └── <info>*      → Uno o más CapAlertInfo
///       ├── <urgency>
///       ├── <severity>
///       ├── <certainty>
///       ├── <description>
///       ├── <instruction>
///       └── <area>*
class CapAlert extends Equatable {
  const CapAlert({
    required this.identifier,
    required this.sender,
    required this.sentDate,
    required this.status,
    required this.msgType,
    required this.scope,
    this.source,
    this.restriction,
    this.addresses,
    this.codes = const [],
    this.note,
    this.references,
    this.incidents,
    this.infoBlocks = const [],
  });

  /// Identificador único del mensaje.
  final String identifier;

  /// Identificador del emisor.
  final String sender;

  /// Fecha y hora de envío.
  final DateTime sentDate;

  /// Estado del mensaje: Actual, Exercise, Test, etc.
  final CapStatus status;

  /// Tipo de mensaje: Alert, Update, Cancel, etc.
  final CapMsgType msgType;

  /// Alcance: Public, Restricted, Private.
  final CapScope scope;

  /// Fuente de la información.
  final String? source;

  /// Restricción de distribución.
  final String? restriction;

  /// Direcciones de destinatarios.
  final String? addresses;

  /// Códigos del mensaje.
  final List<String> codes;

  /// Nota adicional.
  final String? note;

  /// Referencias a mensajes previos.
  final String? references;

  /// Identificador de incidentes relacionados.
  final String? incidents;

  /// Bloques de información (uno por idioma/audiencia).
  final List<CapAlertInfo> infoBlocks;

  // ═══════════════════════════════════════════════════════════
  //  PROPIEDADES DERIVADAS
  // ═══════════════════════════════════════════════════════════

  /// Indica si es una alerta REAL (no simulacro ni prueba).
  bool get isActualAlert => status == CapStatus.actual;

  /// Indica si es un SIMULACRO (Exercise/Drill).
  bool get isDrill => status == CapStatus.exercise;

  /// Indica si es una prueba de sistema.
  bool get isTest =>
      status == CapStatus.test || status == CapStatus.system;

  /// Obtiene el primer bloque de información (principal).
  CapAlertInfo? get primaryInfo =>
      infoBlocks.isNotEmpty ? infoBlocks.first : null;

  /// Obtiene la severidad máxima entre todos los bloques info.
  CapSeverity get maxSeverity {
    if (infoBlocks.isEmpty) return CapSeverity.unknown;
    return infoBlocks.reduce((a, b) =>
        a.severity.numericLevel >= b.severity.numericLevel ? a : b).severity;
  }

  /// Obtiene la urgencia máxima entre todos los bloques info.
  CapUrgency get maxUrgency {
    if (infoBlocks.isEmpty) return CapUrgency.unknown;
    return infoBlocks.reduce((a, b) =>
        a.urgency.numericLevel >= b.urgency.numericLevel ? a : b).urgency;
  }

  /// Calcula la prioridad compuesta máxima.
  int get maxPriorityScore {
    if (infoBlocks.isEmpty) return 0;
    return infoBlocks
        .map((info) => info.priorityScore)
        .reduce((a, b) => a > b ? a : b);
  }

  @override
  List<Object?> get props => [
        identifier, sender, sentDate, status, msgType, scope, infoBlocks,
      ];

  @override
  String toString() =>
      'CapAlert(id: $identifier, status: ${status.xmlValue}, '
      'severity: ${maxSeverity.xmlValue}, urgency: ${maxUrgency.xmlValue})';
}
