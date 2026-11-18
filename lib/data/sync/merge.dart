import 'dart:convert';

/// Coalesce outbox ops for the same entity id.
List<Map<String, dynamic>> coalesce(List<Map<String, dynamic>> ops) {
  final byKey = <String, List<Map<String, dynamic>>>{};
  for (final op in ops) {
    final key = '${op['entity']}:${op['entityId']}';
    byKey.putIfAbsent(key, () => []).add(op);
  }
  final result = <Map<String, dynamic>>[];
  for (final list in byKey.values) {
    var create = false;
    var delete = false;
    Map<String, dynamic>? last;
    for (final op in list) {
      last = op;
      if (op['op'] == 'create') create = true;
      if (op['op'] == 'delete') delete = true;
    }
    if (create && delete) {
      // Never synced — drop both.
      continue;
    }
    if (delete) {
      result.add(last!..['op'] = 'delete');
      continue;
    }
    if (create) {
      result.add(last!..['op'] = 'create');
      continue;
    }
    result.add(last!..['op'] = 'update');
  }
  // Habits before check-ins, then by seq.
  result.sort((a, b) {
    final ae = a['entity'] == 'habit' ? 0 : 1;
    final be = b['entity'] == 'habit' ? 0 : 1;
    if (ae != be) return ae.compareTo(be);
    return (a['seq'] as int).compareTo(b['seq'] as int);
  });
  return result;
}

Map<String, dynamic> decodePayload(String payload) =>
    jsonDecode(payload) as Map<String, dynamic>;
