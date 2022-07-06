library builder;

import 'dart:async';

import 'package:build/build.dart';
import 'package:git/git.dart';

const _defaultOutput = 'lib/src/version.dart';
const _defaultTagPrefix = 'v.';

Builder buildVersion([BuilderOptions? options]) => VersionBuilder(
      (options?.config['output'] as String?) ?? _defaultOutput,
      (options?.config['tag_prefix'] as String?) ?? _defaultTagPrefix,
    );
VersionBuilder buildVersionTester() =>
    VersionBuilder(_defaultOutput, _defaultTagPrefix);

class _Version {
  String shortVersion;
  String longVersion;

  _Version(this.shortVersion, this.longVersion);
}

class VersionBuilder implements Builder {
  final String output;
  final String tagPrefix;

  VersionBuilder(this.output, this.tagPrefix);

  @override
  Future build(BuildStep buildStep) async {
    final versions = await _getVersion();
    await buildStep.writeAsString(buildStep.allowedOutputs.single, '''
// Generated code. Do not modify.
const packageVersion = '${versions.shortVersion}';
const packageBuild = '${versions.longVersion}';
''');
  }

  Future<_Version> _getVersion() async {
    final gitversion = await getVersionFromGit();
    if (gitversion == '') {
      return Future.value(_Version('0.0.0', '0.0.0+0000000'));
    }
    final longVersion = gitversion
        .replaceFirst(RegExp(r'^\D*'), '')
        .replaceFirst(RegExp(r'\-'), '.')
        .replaceFirst(RegExp(r'\-'), '+')
        .replaceAll(RegExp(r'[\n\r]*'), '');
    final shortVersion = longVersion.replaceFirst(RegExp(r'\+.*$'), '');
    return Future.value(_Version(shortVersion, longVersion));
  }

  Future<String> getVersionFromGit() async {
    final pr =
        await runGit(["describe", "--tags", "--long"], throwOnError: false);
    return Future.value(pr.stdout as String);
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        'pubspec.yaml': [output]
      };
}
