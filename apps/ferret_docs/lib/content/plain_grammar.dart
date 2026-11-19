import 'dart:convert';

/// The highlighter behind code blocks ships only a Dart grammar and throws on
/// any other language. The docs show shell, JSON, INI, Kotlin and Python, so
/// they all get this small grammar: comments and quoted strings stand out,
/// the rest stays plain.
final String plainGrammar = jsonEncode({
  'name': 'Plain',
  'scopeName': 'source.plain',
  'patterns': [
    {'name': 'comment.line', 'match': r'(^|\s)(#|//).*$'},
    {'name': 'string.quoted.double', 'match': r'"(?:[^"\\]|\\.)*"'},
    {'name': 'string.quoted.single', 'match': r"'(?:[^'\\]|\\.)*'"},
  ],
});

/// Every language the docs use besides Dart, plus `text` for blocks without
/// one.
const plainLanguages = [
  'text',
  'sh',
  'bash',
  'shell',
  'console',
  'json',
  'ini',
  'kotlin',
  'python',
  'swift',
  'yaml',
  'typescript',
  'js',
];
