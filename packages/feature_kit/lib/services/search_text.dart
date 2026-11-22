/// Text matching for search boxes that ignores case and accents, so
/// "nguyen" finds "Nguyễn", "dang" finds "Đặng" and "jose" finds "José".
abstract final class SearchText {
  /// [text] in lower case with Latin accents and tone marks taken off.
  static String fold(String text) {
    final lower = text.toLowerCase();
    final out = StringBuffer();
    for (final rune in lower.runes) {
      final char = String.fromCharCode(rune);
      out.write(_bases[char] ?? char);
    }

    return out.toString();
  }

  /// Whether every word of [query] is somewhere in one of [fields]. An
  /// empty query matches everything.
  static bool matches(String query, Iterable<String> fields) {
    final words = fold(query).split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    if (words.isEmpty) {
      return true;
    }

    final haystack = fields.map(fold).join('\n');
    return words.every(haystack.contains);
  }

  static final Map<String, String> _bases = {
    for (final MapEntry(key: base, value: chars) in _groups.entries)
      for (final char in chars.split('')) char: base,
    'ß': 'ss',
  };

  static const _groups = {
    'a': 'àáâãäåāăąǎǟǡǻȁȃȧḁạảấầẩẫậắằẳẵặ',
    'b': 'ḃḅḇ',
    'c': 'çćĉċčḉ',
    'd': 'ďḋḍḏḑḓđ',
    'e': 'èéêëēĕėęěȅȇȩḕḗḙḛḝẹẻẽếềểễệ',
    'f': 'ḟ',
    'g': 'ĝğġģǧǵḡ',
    'h': 'ĥȟḣḥḧḩḫẖ',
    'i': 'ìíîïĩīĭįǐȉȋḭḯỉị',
    'j': 'ĵǰ',
    'k': 'ķǩḱḳḵ',
    'l': 'ĺļľḷḹḻḽł',
    'm': 'ḿṁṃ',
    'n': 'ñńņňǹṅṇṉṋ',
    'o': 'òóôõöōŏőơǒǫǭȍȏȫȭȯȱṍṏṑṓọỏốồổỗộớờởỡợø',
    'p': 'ṕṗ',
    'r': 'ŕŗřȑȓṙṛṝṟ',
    's': 'śŝşšșṡṣṥṧṩ',
    't': 'ţťțṫṭṯṱẗ',
    'u': 'ùúûüũūŭůűųưǔǖǘǚǜȕȗṳṵṷṹṻụủứừửữự',
    'v': 'ṽṿ',
    'w': 'ŵẁẃẅẇẉẘ',
    'x': 'ẋẍ',
    'y': 'ýÿŷȳẏẙỳỵỷỹ',
    'z': 'źżžẑẓẕ',
  };
}
