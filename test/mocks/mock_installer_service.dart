import 'dart:io';
import 'package:autonomix/services/installer_service.dart';
import 'package:autonomix/models/install_type.dart';
import 'package:autonomix/models/tracked_app.dart';

class MockInstallerService extends InstallerService {
  bool shouldFail = false;
  String? failureMessage;
  int downloadCount = 0;
  int installCount = 0;
  int uninstallCount = 0;

  final Map<String, ({String? launchCommand, String? packageName})> _installResults = {};

  void setShouldFail(bool fail, {String? message}) {
    shouldFail = fail;
    failureMessage = message;
  }

  void setInstallResult(String packageName, ({String? launchCommand, String? packageName}) result) {
    _installResults[packageName] = result;
  }

  void reset() {
    downloadCount = 0;
    installCount = 0;
    uninstallCount = 0;
    _installResults.clear();
  }

  @override
  Future<File> downloadFile(String url, String filename) async {
    downloadCount++;
    if (shouldFail) {
      throw Exception(failureMessage ?? 'Simulated download error');
    }
    // Create a temporary file
    final tempDir = await Directory.systemTemp.createTemp('mock_download_');
    final file = File('${tempDir.path}/$filename');
    await file.writeAsString('mock content');
    return file;
  }

  @override
  Future<({String? launchCommand, String? packageName})> installPackage(File file, InstallType type) async {
    installCount++;
    if (shouldFail) {
      throw Exception(failureMessage ?? 'Simulated install error');
    }

    final packageName = file.path.split('/').last;
    if (_installResults.containsKey(packageName)) {
      return _installResults[packageName]!;
    }

    return (launchCommand: '/usr/bin/$packageName', packageName: packageName);
  }

  @override
  Future<void> uninstallPackage(TrackedApp app) async {
    uninstallCount++;
    if (shouldFail) {
      throw Exception(failureMessage ?? 'Simulated uninstall error');
    }
  }

  @override
  Future<void> launchApp(TrackedApp app) async {
    if (shouldFail) {
      throw Exception(failureMessage ?? 'Simulated launch error');
    }
  }

  @override
  InstallType? identifyAssetType(String filename) {
    if (filename.endsWith('.deb')) return InstallType.deb;
    if (filename.endsWith('.rpm')) return InstallType.rpm;
    if (filename.endsWith('.AppImage')) return InstallType.appImage;
    if (filename.contains('flatpak')) return InstallType.flatpak;
    if (filename.contains('snap')) return InstallType.snap;
    return null;
  }
}
