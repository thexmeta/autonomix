bool matchesGlobPattern(String input, String pattern) {
  if (pattern.isEmpty) return true;
  if (input.isEmpty) return pattern == '*';

  final regexPattern = _globToRegex(pattern);
  final regex = RegExp(regexPattern, caseSensitive: false);
  return regex.hasMatch(input);
}

String _globToRegex(String pattern) {
  var regex = pattern.trim();

  regex = regex.replaceAll('.', r'\.');
  regex = regex.replaceAll('*', '.*');
  regex = regex.replaceAll('?', '.');

  return '^$regex\$';
}

bool matchesArchitecture(String fileName, String architecture) {
  final lowerName = fileName.toLowerCase();
  final lowerArch = architecture.toLowerCase();

  switch (lowerArch) {
    case 'amd64':
    case 'x86_64':
      return lowerName.contains('amd64') ||
          lowerName.contains('x86_64') ||
          lowerName.contains('x64') ||
          lowerName.contains('64-bit');
    case 'arm64':
    case 'aarch64':
      return lowerName.contains('arm64') ||
          lowerName.contains('aarch64') ||
          lowerName.contains('armv8');
    case 'arm':
    case 'armhf':
    case 'armv7':
      return lowerName.contains('armhf') ||
          lowerName.contains('armv7') ||
          lowerName.contains('arm-');
    case 'i386':
    case 'x86':
      return lowerName.contains('i386') ||
          lowerName.contains('x86') ||
          lowerName.contains('32-bit');
    default:
      return lowerName.contains(lowerArch);
  }
}

List<String> findMatchingArchitectures(
  String fileName,
  List<String> architectures,
) {
  return architectures
      .where((arch) => matchesArchitecture(fileName, arch))
      .toList();
}
