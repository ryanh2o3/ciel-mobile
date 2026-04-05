/// Parses RFC3339 / ISO8601 timestamps from the API (with optional fractional seconds).
DateTime parseApiDateTime(String raw) {
  try {
    return DateTime.parse(raw);
  } on FormatException {
    return DateTime.parse('${raw}Z');
  }
}
