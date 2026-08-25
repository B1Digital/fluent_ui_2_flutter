import 'package:flutter/widgets.dart';

/// The colours Storybook's code panel actually paints.
///
/// Read off the live panel's Prism spans with `getComputedStyle`, not matched by
/// eye: `token keyword` is `rgb(180,116,221)`, `token string` is
/// `rgb(146,195,121)`, `token tag class-name` is `rgb(255,255,182)`,
/// `token attr-name` is `rgb(150,203,254)`, `token punctuation` is
/// `rgb(237,237,237)`.
///
/// Mapping TSX tokens onto Dart ones is mostly literal. The one interesting
/// choice is [namedArgument]: JSX colours attribute *names* differently from
/// values, and a Dart named argument label is the same thing in the same place,
/// so `header:` gets `attr-name` blue. It makes a `FluentAccordionItem(...)`
/// read the way `<AccordionItem ...>` reads.
abstract final class DartSyntaxColors {
  /// Panel background.
  static const Color background = Color(0xFF242424);

  /// The panel's own foreground, used for whitespace and anything unclassified.
  static const Color base = Color(0xFFC6C6C6);

  /// `const`, `final`, `class`, `return`, `if`, and numeric literals — Prism
  /// gives keywords and numbers the same violet.
  static const Color keyword = Color(0xFFB474DD);

  /// String literals, including their quotes.
  static const Color string = Color(0xFF92C379);

  /// `$name` and `${...}` inside a string, so interpolation stays legible
  /// against the surrounding literal.
  static const Color interpolation = Color(0xFFFFFFB6);

  /// Type names: anything starting with a capital.
  static const Color className = Color(0xFFFFFFB6);

  /// A named argument label — `header:`, `onPressed:`.
  static const Color namedArgument = Color(0xFF96CBFE);

  /// Punctuation and operators.
  static const Color punctuation = Color(0xFFEDEDED);

  /// Plain identifiers.
  static const Color identifier = Color(0xFFFFFFFF);

  /// Comments. The captured sample contained none — every story source upstream
  /// generates is comment-free — so unlike its neighbours this value is Prism's
  /// documented comment grey rather than a measurement.
  static const Color comment = Color(0xFF7C7C7C);

  /// `@override` and friends.
  static const Color annotation = Color(0xFFFFFFB6);
}

const Set<String> _keywords = <String>{
  'abstract',
  'as',
  'assert',
  'async',
  'await',
  'base',
  'break',
  'case',
  'catch',
  'class',
  'const',
  'continue',
  'covariant',
  'default',
  'deferred',
  'do',
  'dynamic',
  'else',
  'enum',
  'export',
  'extends',
  'extension',
  'external',
  'factory',
  'false',
  'final',
  'finally',
  'for',
  'get',
  'hide',
  'if',
  'implements',
  'import',
  'in',
  'interface',
  'is',
  'late',
  'library',
  'mixin',
  'new',
  'null',
  'on',
  'operator',
  'part',
  'required',
  'rethrow',
  'return',
  'sealed',
  'set',
  'show',
  'static',
  'super',
  'switch',
  'sync',
  'this',
  'throw',
  'true',
  'try',
  'typedef',
  'var',
  'void',
  'when',
  'while',
  'with',
  'yield',
};

bool _isIdentifierStart(int c) =>
    (c >= 0x41 && c <= 0x5A) ||
    (c >= 0x61 && c <= 0x7A) ||
    c == 0x5F ||
    c == 0x24;

bool _isIdentifierPart(int c) =>
    _isIdentifierStart(c) || (c >= 0x30 && c <= 0x39);

bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

bool _isUpper(int c) => c >= 0x41 && c <= 0x5A;

/// Tokenises Dart into a coloured [TextSpan] tree.
///
/// A lexer, not a parser: it never builds a syntax tree, and it classifies
/// `Uppercase` identifiers as types by convention rather than by resolution.
/// That heuristic is wrong on SCREAMING_CASE constants, which Dart style makes
/// rare, and being wrong only ever changes a colour.
///
/// Order matters and is the only subtle thing here — comments are recognised
/// before strings so a `//` inside a literal does not start one, and strings are
/// recognised before everything else so a `//` in a URL survives.
TextSpan highlightDart(String source, {TextStyle? style}) {
  final List<TextSpan> spans = <TextSpan>[];
  final int length = source.length;
  int index = 0;
  int plainFrom = 0;

  void flushPlain(int upto) {
    if (upto > plainFrom) {
      spans.add(TextSpan(text: source.substring(plainFrom, upto)));
    }
  }

  void emit(int start, int end, Color color) {
    flushPlain(start);
    spans.add(
      TextSpan(
        text: source.substring(start, end),
        style: TextStyle(color: color),
      ),
    );
    plainFrom = end;
  }

  /// Consumes a string literal starting at [start] and colours it, splitting out
  /// interpolations. Returns the index just past the closing quote.
  int scanString(int start, {required bool raw}) {
    final int quote = source.codeUnitAt(start);
    int i = start;
    // A triple quote is only triple if all three match.
    final bool triple =
        i + 2 < length &&
        source.codeUnitAt(i + 1) == quote &&
        source.codeUnitAt(i + 2) == quote;
    final int delimiterLength = triple ? 3 : 1;
    i += delimiterLength;

    int literalFrom = start;

    bool atClose(int at) {
      if (source.codeUnitAt(at) != quote) {
        return false;
      }
      if (!triple) {
        return true;
      }
      return at + 2 < length &&
          source.codeUnitAt(at + 1) == quote &&
          source.codeUnitAt(at + 2) == quote;
    }

    while (i < length) {
      final int c = source.codeUnitAt(i);

      if (!raw && c == 0x5C) {
        i += 2;
        continue;
      }

      if (atClose(i)) {
        i += delimiterLength;
        emit(literalFrom, i, DartSyntaxColors.string);
        return i;
      }

      // `$name` / `${expr}` — raw strings have neither.
      if (!raw && c == 0x24 && i + 1 < length) {
        final int next = source.codeUnitAt(i + 1);
        int interpEnd = -1;
        if (next == 0x7B) {
          int depth = 0;
          for (int j = i + 1; j < length; j += 1) {
            final int d = source.codeUnitAt(j);
            if (d == 0x7B) {
              depth += 1;
            } else if (d == 0x7D) {
              depth -= 1;
              if (depth == 0) {
                interpEnd = j + 1;
                break;
              }
            }
          }
        } else if (_isIdentifierStart(next)) {
          int j = i + 1;
          while (j < length && _isIdentifierPart(source.codeUnitAt(j))) {
            j += 1;
          }
          interpEnd = j;
        }
        if (interpEnd > 0) {
          emit(literalFrom, i, DartSyntaxColors.string);
          emit(i, interpEnd, DartSyntaxColors.interpolation);
          literalFrom = interpEnd;
          i = interpEnd;
          continue;
        }
      }

      i += 1;
    }

    // Unterminated: colour to end rather than throwing. This renders a demo,
    // and a half-typed literal is not worth an exception.
    emit(literalFrom, length, DartSyntaxColors.string);
    return length;
  }

  while (index < length) {
    final int c = source.codeUnitAt(index);

    // Line comment.
    if (c == 0x2F &&
        index + 1 < length &&
        source.codeUnitAt(index + 1) == 0x2F) {
      int end = source.indexOf('\n', index);
      if (end < 0) {
        end = length;
      }
      emit(index, end, DartSyntaxColors.comment);
      index = end;
      continue;
    }

    // Block comment. Dart's nest, so a depth counter is required — a plain
    // search for the first `*/` mis-terminates `/* /* */ */`.
    if (c == 0x2F &&
        index + 1 < length &&
        source.codeUnitAt(index + 1) == 0x2A) {
      int depth = 0;
      int i = index;
      while (i < length) {
        if (i + 1 < length &&
            source.codeUnitAt(i) == 0x2F &&
            source.codeUnitAt(i + 1) == 0x2A) {
          depth += 1;
          i += 2;
          continue;
        }
        if (i + 1 < length &&
            source.codeUnitAt(i) == 0x2A &&
            source.codeUnitAt(i + 1) == 0x2F) {
          depth -= 1;
          i += 2;
          if (depth == 0) {
            break;
          }
          continue;
        }
        i += 1;
      }
      emit(index, i, DartSyntaxColors.comment);
      index = i;
      continue;
    }

    // Raw string.
    if ((c == 0x72 || c == 0x52) &&
        index + 1 < length &&
        (source.codeUnitAt(index + 1) == 0x27 ||
            source.codeUnitAt(index + 1) == 0x22)) {
      final bool precededByIdentifier =
          index > 0 && _isIdentifierPart(source.codeUnitAt(index - 1));
      if (!precededByIdentifier) {
        flushPlain(index);
        plainFrom = index;
        index = scanString(index + 1, raw: true);
        continue;
      }
    }

    if (c == 0x27 || c == 0x22) {
      index = scanString(index, raw: false);
      continue;
    }

    if (c == 0x40 &&
        index + 1 < length &&
        _isIdentifierStart(source.codeUnitAt(index + 1))) {
      int i = index + 1;
      while (i < length && _isIdentifierPart(source.codeUnitAt(i))) {
        i += 1;
      }
      emit(index, i, DartSyntaxColors.annotation);
      index = i;
      continue;
    }

    // Number. Guarded on the previous character so the `20` of `size20` is not
    // split out of its identifier.
    if (_isDigit(c) &&
        (index == 0 || !_isIdentifierPart(source.codeUnitAt(index - 1)))) {
      int i = index;
      if (c == 0x30 &&
          i + 1 < length &&
          (source.codeUnitAt(i + 1) == 0x78 ||
              source.codeUnitAt(i + 1) == 0x58)) {
        i += 2;
        while (i < length && _isHexDigit(source.codeUnitAt(i))) {
          i += 1;
        }
      } else {
        while (i < length && _isDigit(source.codeUnitAt(i))) {
          i += 1;
        }
        if (i < length &&
            source.codeUnitAt(i) == 0x2E &&
            i + 1 < length &&
            _isDigit(source.codeUnitAt(i + 1))) {
          i += 1;
          while (i < length && _isDigit(source.codeUnitAt(i))) {
            i += 1;
          }
        }
        if (i < length &&
            (source.codeUnitAt(i) == 0x65 || source.codeUnitAt(i) == 0x45)) {
          int j = i + 1;
          if (j < length &&
              (source.codeUnitAt(j) == 0x2B || source.codeUnitAt(j) == 0x2D)) {
            j += 1;
          }
          if (j < length && _isDigit(source.codeUnitAt(j))) {
            i = j;
            while (i < length && _isDigit(source.codeUnitAt(i))) {
              i += 1;
            }
          }
        }
      }
      emit(index, i, DartSyntaxColors.keyword);
      index = i;
      continue;
    }

    if (_isIdentifierStart(c)) {
      int i = index;
      while (i < length && _isIdentifierPart(source.codeUnitAt(i))) {
        i += 1;
      }
      final String word = source.substring(index, i);

      if (_keywords.contains(word)) {
        emit(index, i, DartSyntaxColors.keyword);
      } else if (_isUpper(c)) {
        emit(index, i, DartSyntaxColors.className);
      } else if (i < length &&
          source.codeUnitAt(i) == 0x3A &&
          !_isTernaryColon(source, i)) {
        emit(index, i, DartSyntaxColors.namedArgument);
      } else {
        emit(index, i, DartSyntaxColors.identifier);
      }
      index = i;
      continue;
    }

    // Punctuation and operators. Whitespace deliberately falls through to the
    // plain run so it costs no span.
    if (c > 0x20) {
      emit(index, index + 1, DartSyntaxColors.punctuation);
    }
    index += 1;
  }

  flushPlain(length);
  return TextSpan(
    style: (style ?? const TextStyle()).copyWith(color: DartSyntaxColors.base),
    children: spans,
  );
}

bool _isHexDigit(int c) =>
    _isDigit(c) || (c >= 0x41 && c <= 0x46) || (c >= 0x61 && c <= 0x66);

/// True when the `:` at [colon] closes a `? :` rather than labelling an
/// argument. Only has to be right for the code these demo pages contain, where
/// the distinguishing feature is a `?` earlier on the same line.
bool _isTernaryColon(String source, int colon) {
  for (int i = colon - 1; i >= 0; i -= 1) {
    final int c = source.codeUnitAt(i);
    if (c == 0x0A) {
      return false;
    }
    if (c == 0x3F) {
      return true;
    }
  }
  return false;
}
