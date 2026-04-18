import 'package:intl/intl.dart';

final _daMonthNames = [
  '', 'jan', 'feb', 'mar', 'apr', 'maj', 'jun',
  'jul', 'aug', 'sep', 'okt', 'nov', 'dec',
];

String formatDanishDate(DateTime date) =>
    '${date.day}. ${_daMonthNames[date.month]}';

String formatMonthDay(int month, int day) =>
    '$day. ${_daMonthNames[month]}';

String formatClosedSeasonRange(int startMonth, int startDay, int endMonth, int endDay) =>
    '${formatMonthDay(startMonth, startDay)} – ${formatMonthDay(endMonth, endDay)}';
