import 'dart:convert';

import 'package:build_test/build_test.dart';
import 'package:build_git_version/builder.dart';
import 'package:test/test.dart';

class VersionBits {
  String subVersion;
  String patch;
  String commit;

  VersionBits(this.subVersion, this.patch, this.commit);
}

void main() {
  group('Just some build tests', () {
    late VersionBuilder vBuilder;
    late VersionBits vBits;

    setUp(() async {
      vBuilder = buildVersionTester();
      final gitVersion = await vBuilder.getVersionFromGit();
      final bits = gitVersion
          .replaceFirst(RegExp(r'v.'), '')
          .replaceAll(RegExp(r'[\n\r]*'), '')
          .split('-');
      if (bits.length == 3) {
        vBits = VersionBits(bits[0], bits[1], bits[2]);
      } else {
        vBits = VersionBits('0.0', '0', '0000000');
      }
    });

    test('getVersions', () async {
      await testBuilder(vBuilder, {
        'pkg|pubspec.yaml': jsonEncode({'name': 'pkg'})
      }, outputs: {
        'pkg|lib/src/version.dart': '''
// Generated code. Do not modify.
const packageVersion = '${vBits.subVersion}.${vBits.patch}';
const packageBuild = '${vBits.subVersion}.${vBits.patch}+${vBits.commit}';
'''
      });
    });
  });
}
