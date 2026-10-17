// ============================================================================
// SismoGuard — Parser de Mensajes CAP 1.2 XML
// ============================================================================
// Datasource que parsea mensajes XML bajo el Protocolo de Alerta Común
// (CAP 1.2, estándar OASIS) y los convierte a entidades de dominio.
//
// Soporta:
// - Namespace CAP: urn:oasis:names:tc:emergency:cap:1.2
// - Múltiples bloques <info> (multi-idioma)
// - Múltiples bloques <area> con polígonos/círculos
// - Validación de campos obligatorios
// ============================================================================

import 'package:xml/xml.dart';

import '../../../../core/constants/cap_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../domain/entities/cap_alert.dart';

/// Interfaz del datasource para procesamiento de mensajes CAP.
abstract class CapMessageDatasource {
  /// Parsea un string XML CAP 1.2 a una entidad [CapAlert].
  CapAlert parseCapXml(String xmlString);

  /// Parsea múltiples mensajes CAP de un feed Atom/RSS.
  List<CapAlert> parseCapFeed(String feedXml);

  /// Valida si un string XML es un mensaje CAP 1.2 válido.
  bool isValidCapMessage(String xmlString);
}

/// Implementación del parser de mensajes CAP 1.2.
class CapMessageDatasourceImpl implements CapMessageDatasource {
  @override
  CapAlert parseCapXml(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final alertElement = document.rootElement;

      // Validar que el elemento raíz es <alert>
      if (alertElement.name.local != 'alert') {
        throw const CapParsingException(
          message: 'El elemento raíz no es <alert>',
        );
      }

      return _parseAlertElement(alertElement);
    } on XmlParserException catch (e) {
      throw CapParsingException(
        message: 'Error de parsing XML: ${e.message}',
        xmlFragment: xmlString.length > 200
            ? '${xmlString.substring(0, 200)}...'
            : xmlString,
      );
    }
  }

  @override
  List<CapAlert> parseCapFeed(String feedXml) {
    try {
      final document = XmlDocument.parse(feedXml);
      final alerts = <CapAlert>[];

      // Buscar elementos <alert> directos o dentro de <entry> (Atom)
      final alertElements = document.findAllElements('alert');
      for (final alertElement in alertElements) {
        try {
          alerts.add(_parseAlertElement(alertElement));
        } catch (_) {
          // Saltar alertas malformadas en un feed
          continue;
        }
      }

      return alerts;
    } catch (e) {
      throw CapParsingException(
        message: 'Error al parsear feed CAP: $e',
      );
    }
  }

  @override
  bool isValidCapMessage(String xmlString) {
    try {
      final document = XmlDocument.parse(xmlString);
      final root = document.rootElement;
      return root.name.local == 'alert' &&
          _findElement(root, 'identifier') != null &&
          _findElement(root, 'sender') != null &&
          _findElement(root, 'sent') != null &&
          _findElement(root, 'status') != null &&
          _findElement(root, 'msgType') != null;
    } catch (_) {
      return false;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  PARSING INTERNO
  // ═══════════════════════════════════════════════════════════

  /// Parsea un elemento <alert> a una entidad [CapAlert].
  CapAlert _parseAlertElement(XmlElement alertElement) {
    // ── Campos obligatorios del <alert> ──
    final identifier = _getRequiredText(alertElement, 'identifier');
    final sender = _getRequiredText(alertElement, 'sender');
    final sentText = _getRequiredText(alertElement, 'sent');
    final statusText = _getRequiredText(alertElement, 'status');
    final msgTypeText = _getRequiredText(alertElement, 'msgType');
    final scopeText = _getRequiredText(alertElement, 'scope');

    // ── Campos opcionales del <alert> ──
    final source = _getOptionalText(alertElement, 'source');
    final restriction = _getOptionalText(alertElement, 'restriction');
    final addresses = _getOptionalText(alertElement, 'addresses');
    final note = _getOptionalText(alertElement, 'note');
    final references = _getOptionalText(alertElement, 'references');
    final incidents = _getOptionalText(alertElement, 'incidents');

    // Códigos
    final codes = alertElement
        .findAllElements('code')
        .map((e) => e.innerText.trim())
        .toList();

    // ── Parsear bloques <info> ──
    final infoBlocks = alertElement
        .findAllElements('info')
        .map(_parseInfoElement)
        .toList();

    return CapAlert(
      identifier: identifier,
      sender: sender,
      sentDate: DateTime.tryParse(sentText) ?? DateTime.now(),
      status: CapStatus.fromXml(statusText),
      msgType: CapMsgType.fromXml(msgTypeText),
      scope: CapScope.fromXml(scopeText),
      source: source,
      restriction: restriction,
      addresses: addresses,
      codes: codes,
      note: note,
      references: references,
      incidents: incidents,
      infoBlocks: infoBlocks,
    );
  }

  /// Parsea un elemento <info> a una entidad [CapAlertInfo].
  CapAlertInfo _parseInfoElement(XmlElement infoElement) {
    // ── Campos obligatorios ──
    final categoryText = _getRequiredText(infoElement, 'category');
    final event = _getRequiredText(infoElement, 'event');
    final urgencyText = _getRequiredText(infoElement, 'urgency');
    final severityText = _getRequiredText(infoElement, 'severity');
    final certaintyText = _getRequiredText(infoElement, 'certainty');

    // ── Campos opcionales ──
    final language = _getOptionalText(infoElement, 'language') ?? 'es';
    final audience = _getOptionalText(infoElement, 'audience');
    final effectiveText = _getOptionalText(infoElement, 'effective');
    final expiresText = _getOptionalText(infoElement, 'expires');
    final senderName = _getOptionalText(infoElement, 'senderName');
    final headline = _getOptionalText(infoElement, 'headline');
    final description = _getOptionalText(infoElement, 'description');
    final instruction = _getOptionalText(infoElement, 'instruction');
    final contact = _getOptionalText(infoElement, 'contact');

    // Response types
    final responseTypes = infoElement
        .findAllElements('responseType')
        .map((e) => CapResponseType.fromXml(e.innerText.trim()))
        .toList();

    // Áreas
    final areas = infoElement
        .findAllElements('area')
        .map(_parseAreaElement)
        .toList();

    return CapAlertInfo(
      language: language,
      category: CapCategory.fromXml(categoryText),
      event: event,
      urgency: CapUrgency.fromXml(urgencyText),
      severity: CapSeverity.fromXml(severityText),
      certainty: CapCertainty.fromXml(certaintyText),
      responseTypes: responseTypes,
      audience: audience,
      effectiveDate:
          effectiveText != null ? DateTime.tryParse(effectiveText) : null,
      expiresDate:
          expiresText != null ? DateTime.tryParse(expiresText) : null,
      senderName: senderName,
      headline: headline,
      description: description,
      instruction: instruction,
      contact: contact,
      areas: areas,
    );
  }

  /// Parsea un elemento <area> a una entidad [CapArea].
  CapArea _parseAreaElement(XmlElement areaElement) {
    final description = _getRequiredText(areaElement, 'areaDesc');

    final polygons = areaElement
        .findAllElements('polygon')
        .map((e) => e.innerText.trim())
        .toList();

    final circles = areaElement
        .findAllElements('circle')
        .map((e) => e.innerText.trim())
        .toList();

    final geocodes = <String, String>{};
    for (final geocode in areaElement.findAllElements('geocode')) {
      final valueName = _getOptionalText(geocode, 'valueName');
      final value = _getOptionalText(geocode, 'value');
      if (valueName != null && value != null) {
        geocodes[valueName] = value;
      }
    }

    final altitudeText = _getOptionalText(areaElement, 'altitude');
    final ceilingText = _getOptionalText(areaElement, 'ceiling');

    return CapArea(
      description: description,
      polygons: polygons,
      circles: circles,
      geocodes: geocodes,
      altitude: altitudeText != null ? double.tryParse(altitudeText) : null,
      ceiling: ceilingText != null ? double.tryParse(ceilingText) : null,
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  HELPERS XML
  // ═══════════════════════════════════════════════════════════

  /// Busca un elemento hijo por nombre (ignorando namespace).
  XmlElement? _findElement(XmlElement parent, String name) {
    try {
      return parent.findAllElements(name).firstOrNull;
    } catch (_) {
      return null;
    }
  }

  /// Obtiene el texto de un elemento hijo requerido.
  /// Lanza [CapParsingException] si no existe.
  String _getRequiredText(XmlElement parent, String elementName) {
    final element = _findElement(parent, elementName);
    if (element == null) {
      throw CapParsingException(
        message: 'Elemento requerido <$elementName> no encontrado',
      );
    }
    return element.innerText.trim();
  }

  /// Obtiene el texto de un elemento hijo opcional.
  /// Retorna null si no existe.
  String? _getOptionalText(XmlElement parent, String elementName) {
    final element = _findElement(parent, elementName);
    if (element == null) return null;
    final text = element.innerText.trim();
    return text.isEmpty ? null : text;
  }
}
