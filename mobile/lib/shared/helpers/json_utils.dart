/// Pembaca JSON yang tidak crash bila field kosong / bertipe lain.
String asString(dynamic v, [String fallback = '']) => v is String ? v : fallback;

String? asStringOrNull(dynamic v) => v is String ? v : null;

int asInt(dynamic v, [int fallback = 0]) => v is num ? v.toInt() : fallback;

int? asIntOrNull(dynamic v) => v is num ? v.toInt() : null;

double asDouble(dynamic v, [double fallback = 0]) =>
    v is num ? v.toDouble() : fallback;

bool asBool(dynamic v, [bool fallback = false]) => v is bool ? v : fallback;

DateTime asDate(dynamic v) {
  if (v is String) {
    final parsed = DateTime.tryParse(v);
    if (parsed != null) return parsed.toLocal();
  }
  return DateTime.now();
}

Map<String, dynamic> asMap(dynamic v) =>
    v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};

List<dynamic> asList(dynamic v) => v is List ? v : const [];
