import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Clean Architecture Purity Guards', () {
    test('Domain layer does not import Flutter UI, Presentation, or Infrastructure', () {
      final domainDir = Directory(r'lib/domain');
      if (!domainDir.existsSync()) return;

      final dartFiles = domainDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(content.contains('package:flutter/material.dart'), isFalse,
            reason: '\ must not import flutter/material.dart');
        expect(content.contains('package:mouin/presentation/'), isFalse,
            reason: '\ must not import presentation layer');
        expect(content.contains('package:mouin/infrastructure/'), isFalse,
            reason: '\ must not import infrastructure layer');
      }
    });

    test('Application layer does not import Presentation or Infrastructure directly', () {
      final appDir = Directory(r'lib/application');
      if (!appDir.existsSync()) return;

      final dartFiles = appDir.listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'));
      for (final file in dartFiles) {
        final content = file.readAsStringSync();
        expect(content.contains('package:flutter/material.dart'), isFalse,
            reason: '\ must not import flutter/material.dart');
        expect(content.contains('package:mouin/presentation/'), isFalse,
            reason: '\ must not import presentation layer');
        expect(content.contains('package:mouin/infrastructure/'), isFalse,
            reason: '\ must not import infrastructure layer');
      }
    });
  });
}
