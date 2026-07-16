class SearchQueryParser {
  final DateTime? date;
  final double? amount;
  final String cleanDescriptionQuery;

  SearchQueryParser({
    this.date,
    this.amount,
    required this.cleanDescriptionQuery,
  });

  factory SearchQueryParser.parse(String query) {
    query = query.toLowerCase().trim();
    if (query.isEmpty) {
      return SearchQueryParser(cleanDescriptionQuery: '');
    }

    DateTime? date;
    double? amount;
    int? detectedYear;
    int? detectedDay;
    int? detectedMonth;

    // 1. Try parsing full standard dates: YYYY-MM-DD, DD-MM-YYYY, DD/MM/YYYY
    final dmyRegex = RegExp(r'\b(\d{1,2})[\-/](\d{1,2})[\-/](\d{4})\b');
    var match = dmyRegex.firstMatch(query);
    if (match != null) {
      detectedDay = int.parse(match.group(1)!);
      detectedMonth = int.parse(match.group(2)!);
      detectedYear = int.parse(match.group(3)!);
      date = DateTime(detectedYear, detectedMonth, detectedDay);
    } else {
      final ymdRegex = RegExp(r'\b(\d{4})[\-/](\d{1,2})[\-/](\d{1,2})\b');
      match = ymdRegex.firstMatch(query);
      if (match != null) {
        detectedYear = int.parse(match.group(1)!);
        detectedMonth = int.parse(match.group(2)!);
        detectedDay = int.parse(match.group(3)!);
        date = DateTime(detectedYear, detectedMonth, detectedDay);
      }
    }

    // 2. Parse written Indonesian date: e.g. "17 juli 2026", "17 juli", "juli 2026"
    if (date == null) {
      const indonesianMonths = {
        'januari': 1, 'jan': 1,
        'februari': 2, 'feb': 2,
        'maret': 3, 'mar': 3,
        'april': 4, 'apr': 4,
        'mei': 5,
        'juni': 6, 'jun': 6,
        'juli': 7, 'jul': 7,
        'agustus': 8, 'agu': 8, 'agt': 8,
        'september': 9, 'sep': 9,
        'oktober': 10, 'okt': 10,
        'november': 11, 'nov': 11,
        'desember': 12, 'des': 12,
      };

      String? foundMonthName;
      for (final monthName in indonesianMonths.keys) {
        if (RegExp('\\b$monthName\\b').hasMatch(query)) {
          foundMonthName = monthName;
          detectedMonth = indonesianMonths[monthName];
          break;
        }
      }

      if (detectedMonth != null && foundMonthName != null) {
        // Extract other numbers in the query
        final numbers = RegExp(r'\b\d+\b').allMatches(query)
            .map((m) => int.parse(m.group(0)!))
            .toList();

        for (final num in numbers) {
          if (num >= 2000 && num <= 2100) {
            detectedYear = num;
          } else if (num >= 1 && num <= 31) {
            detectedDay ??= num;
          }
        }

        detectedYear ??= DateTime.now().year;
        detectedDay ??= 1;
        date = DateTime(detectedYear, detectedMonth, detectedDay);
      }
    }

    // 3. Find nominal amount, avoiding numbers that were part of the date
    final cleanQuery = query.replaceAll(RegExp(r'[^\d\s\.,]'), '');
    final matches = RegExp(r'\b\d+[\d\.,]*\b').allMatches(cleanQuery);
    for (final m in matches) {
      final raw = m.group(0)!;
      final stripped = raw.replaceAll('.', '').replaceAll(',', '');
      final val = double.tryParse(stripped);
      if (val != null) {
        final valInt = val.toInt();
        // Ignore values that represent the detected day, month, or year
        if (valInt == detectedYear || valInt == detectedMonth || valInt == detectedDay) {
          continue;
        }
        // Also ignore standard small values unless they are explicitly written with currency format
        if (val >= 100) {
          amount = val;
          break;
        }
      }
    }

    return SearchQueryParser(
      date: date,
      amount: amount,
      cleanDescriptionQuery: query,
    );
  }
}
