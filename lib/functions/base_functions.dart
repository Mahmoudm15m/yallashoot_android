String formatTime(String input) {
  return input;
}
String extractIdFromUrl(String url) {
  RegExp regExp = RegExp(r'\/news\/(\d+)');
  Match? match = regExp.firstMatch(url);
  return match != null ? match.group(1)! : '';
}