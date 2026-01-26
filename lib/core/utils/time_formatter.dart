String formatDate(DateTime date) {
  String twoDigits(int n) => n.toString().padLeft(2, '0');
  return '${twoDigits(date.day)}.${twoDigits(date.month)}.${date.year} ${twoDigits(date.hour)}:${twoDigits(date.minute)}';
}
