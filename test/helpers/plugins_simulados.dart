import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:printing/printing.dart';

/// Canales nativos que la app usa y que en las pruebas no existen.
/// Cada simulador responde como lo haría el plugin y registra las llamadas.

const _canalVoz = MethodChannel('plugin.csdcorp.com/speech_to_text');
const _canalImpresion = MethodChannel('net.nfet.printing');

TestDefaultBinaryMessenger get _mensajero => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

/// Reconocimiento de voz simulado.
class VozSimulada {
  VozSimulada({required this.disponible}) {
    _mensajero.setMockMethodCallHandler(_canalVoz, (llamada) async {
      llamadas.add(llamada.method);
      switch (llamada.method) {
        case 'initialize':
          return disponible;
        case 'has_permission':
          return disponible;
        case 'listen':
          return true;
        case 'locales':
          return <String>[];
      }
      return null;
    });
    addTearDown(() => _mensajero.setMockMethodCallHandler(_canalVoz, null));
  }

  final bool disponible;
  final List<String> llamadas = [];

  /// Envía a la app un texto reconocido, como lo hace el plugin nativo.
  Future<void> reconocer(String palabras, {bool esFinal = false}) async {
    final datos = jsonEncode({
      'alternates': [
        {'recognizedWords': palabras, 'confidence': 0.9},
      ],
      'finalResult': esFinal,
    });
    await _mensajero.handlePlatformMessage(
      _canalVoz.name,
      const StandardMethodCodec().encodeMethodCall(MethodCall('textRecognition', datos)),
      (_) {},
    );
  }
}

/// Crea el plugin de impresión fuera de las pruebas (se llama en setUpAll).
///
/// El plugin registra su manejador de canal la primera vez que se usa, ligado a
/// la zona de ese momento. Si eso ocurre dentro de un testWidgets, en la prueba
/// siguiente sus futuros quedan en una zona que ya no avanza.
Future<void> prepararImpresion() async {
  TestWidgetsFlutterBinding.ensureInitialized(); // también en archivos de pruebas puras de Dart
  _mensajero.setMockMethodCallHandler(_canalImpresion, (_) async => {
        'directPrint': false, 'dynamicLayout': false, 'canPrint': true, 'canConvertHtml': false,
        'canShare': true, 'canRaster': false, 'canListPrinters': false,
      });
  await Printing.info();
  _mensajero.setMockMethodCallHandler(_canalImpresion, null);
}

/// Impresión / compartición de PDF simulada.
class ImpresionSimulada {
  ImpresionSimulada() {
    _mensajero.setMockMethodCallHandler(_canalImpresion, (llamada) async {
      llamadas.add(llamada.method);
      final args = (llamada.arguments as Map?) ?? const {};
      switch (llamada.method) {
        case 'printingInfo':
          return {
            'directPrint': false, 'dynamicLayout': false, 'canPrint': true, 'canConvertHtml': false,
            'canShare': true, 'canRaster': false, 'canListPrinters': false,
          };
        case 'printPdf':
          // El sistema pide el documento y luego avisa que terminó.
          final formato = {
            'job': args['job'], 'width': args['width'], 'height': args['height'],
            'marginLeft': args['marginLeft'], 'marginTop': args['marginTop'],
            'marginRight': args['marginRight'], 'marginBottom': args['marginBottom'],
          };
          await _mensajero.handlePlatformMessage(
            _canalImpresion.name,
            const StandardMethodCodec().encodeMethodCall(MethodCall('onLayout', formato)),
            (datos) {
              if (datos != null) {
                final pdf = const StandardMethodCodec().decodeEnvelope(datos);
                if (pdf is Uint8List) documentos.add(pdf);
              }
            },
          );
          await _mensajero.handlePlatformMessage(
            _canalImpresion.name,
            const StandardMethodCodec()
                .encodeMethodCall(MethodCall('onCompleted', {'job': args['job'], 'completed': true})),
            (_) {},
          );
          return 1;
        case 'sharePdf':
          final bytes = args['doc'];
          if (bytes is Uint8List) documentos.add(bytes);
          return 1;
      }
      return null;
    });
    addTearDown(() => _mensajero.setMockMethodCallHandler(_canalImpresion, null));
  }

  final List<String> llamadas = [];

  /// PDF generados (bytes) que la app entregó al sistema.
  final List<Uint8List> documentos = [];
}
