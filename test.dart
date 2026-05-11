import 'dart:core';

bool matchesGlobPattern(String input, String pattern) {
  if (pattern.isEmpty) return true;
  if (input.isEmpty) return pattern == '*';
  final patterns = pattern.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty);
  for (final p in patterns) {
    var regexPattern = p.trim();
    regexPattern = regexPattern.replaceAll('.', r'\.');
    regexPattern = regexPattern.replaceAll('*', '.*');
    regexPattern = regexPattern.replaceAll('?', '.');
    regexPattern = '^$regexPattern\$';
    final regex = RegExp(regexPattern, caseSensitive: false);
    if (regex.hasMatch(input)) return true;
  }
  return false;
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
    default:
      return lowerName.contains(lowerArch);
  }
}

void main() {
  String name = "mq-x86_64-unknown-linux-gnu.deb";
  print("Glob match: ${matchesGlobPattern(name, '*gnu.deb')}");
  print("Arch match: ${matchesArchitecture(name, 'amd64')}");
}
