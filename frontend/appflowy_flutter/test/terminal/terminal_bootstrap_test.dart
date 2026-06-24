import 'dart:convert';
import 'dart:io';

import 'package:appflowy/plugins/terminal/bootstrap/terminal_bootstrap.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TerminalBootstrap', () {
    late Directory tmp;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('osn_test');
    });

    tearDown(() {
      if (tmp.existsSync()) {
        tmp.deleteSync(recursive: true);
      }
    });

    test('ensureWorkspace creates dir, .mcp.json and CLAUDE.md', () async {
      final dir = await TerminalBootstrap.ensureWorkspace(customDir: tmp.path);

      expect(dir, tmp.path);
      expect(Directory(dir).existsSync(), isTrue);
      expect(File('$dir/.mcp.json').existsSync(), isTrue);
      expect(File('$dir/CLAUDE.md').existsSync(), isTrue);
    });

    test('ensureWorkspace does not overwrite an existing .mcp.json', () async {
      const customContent = '{"custom": "user content"}';
      final mcpFile = File('${tmp.path}/.mcp.json');
      mcpFile.writeAsStringSync(customContent);

      await TerminalBootstrap.ensureWorkspace(customDir: tmp.path);

      expect(mcpFile.readAsStringSync(), customContent);
    });

    test('mcpJsonTemplate is valid JSON with uvx appflowy server', () {
      final decoded =
          jsonDecode(TerminalBootstrap.mcpJsonTemplate()) as Map<String, dynamic>;

      final servers = decoded['mcpServers'] as Map<String, dynamic>;
      final appflowy = servers['appflowy'] as Map<String, dynamic>;

      expect(appflowy['command'], 'uvx');
      expect(appflowy['args'], contains('appflowy-mcp'));
    });
  });
}
