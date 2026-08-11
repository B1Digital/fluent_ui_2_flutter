import 'package:fluent_2_web/src/charts/internal/vega/expression.dart';
import 'package:fluent_2_web/src/charts/internal/vega/js_value.dart';
import 'package:flutter_test/flutter_test.dart';

/// One expected result, transcribed from a Node run of the upstream evaluator.
typedef _Row = ({String expr, Object? expected});

/// The datum every row in the matrix is evaluated against.
///
/// One value of each JavaScript type the port can hold, so the operator set
/// crosses the type set: number, fractional number, string, boolean, null,
/// array and object. `datum.missing` is deliberately absent — a miss is
/// `undefined`, which is a type of its own.
const Map<String, Object?> _datum = <String, Object?>{
  'n': 3,
  'f': 1.5,
  's': 'x',
  'b': true,
  'z': null,
  'arr': <Object?>[1, 2],
  'obj': <String, Object?>{'k': 9},
};

void main() {
  Object? eval(String expr) => evaluateVegaExpression(expr, _datum);

  // Every row below was produced by running the upstream evaluator under node:
  //
  //   const { safeEvaluateExpression } = require(
  //     'crawlers/fluentui-react-charts/node_modules/@fluentui/react-charts/'
  //     + 'lib-commonjs/components/VegaDeclarativeChart/'
  //     + 'VegaLiteExpressionEvaluator.js');
  //
  // — the shipped build of the crawled
  // `VegaDeclarativeChart/VegaLiteExpressionEvaluator.ts`, whose `hasOwn`,
  // `SAFE_FUNCTIONS`, `ALLOWED_IDENTIFIERS` and parser bodies were diffed
  // against the TypeScript before the run. The result was printed with its
  // `typeof`, so `undefined` is distinguished from `null` and `-0` from `0`;
  // it is NOT a `JSON.stringify` transcript, which would have flattened both.
  // Every numeric literal in this table is therefore a recorded output, not a
  // chosen one, and any divergence is a port bug.
  const rows = <_Row>[
    // `+` is the one operator that reads its operands' types (ts:363-367);
    // every other arithmetic operator coerces unconditionally.
    (expr: 'datum.n + datum.f', expected: 4.5),
    (expr: 'datum.n + datum.s', expected: '3x'),
    (expr: 'datum.s + datum.n', expected: 'x3'),
    (expr: 'datum.n + datum.b', expected: 4),
    (expr: 'datum.n + datum.z', expected: 3),
    (expr: 'datum.s + datum.z', expected: 'xnull'),
    (expr: 'datum.n - datum.b', expected: 2),
    (expr: 'datum.n * datum.b', expected: 3),
    (expr: 'datum.n / datum.f', expected: 2),
    (expr: 'datum.n % 2', expected: 1),
    // `%` keeps the sign of the DIVIDEND in JavaScript and of the divisor in
    // Dart, and unary minus binds tighter than `%` (ts:395-409, :375-393), so
    // this is (-3) % 2.
    (expr: '-datum.n % 2', expected: -1),
    // Equality: the loose/strict pair over every type that differs between
    // them (ts:310-333).
    (expr: 'datum.n == 3', expected: true),
    (expr: "datum.n == '3'", expected: true),
    (expr: "datum.n === '3'", expected: false),
    (expr: 'datum.z == datum.missing', expected: true),
    (expr: 'datum.z === datum.missing', expected: false),
    (expr: 'datum.b == 1', expected: true),
    (expr: 'datum.b === 1', expected: false),
    // The equality loop is left-associative, so this is `(1 == 1) == 1`, i.e.
    // `true == 1` (ts:311-332).
    (expr: '1 == 1 == 1', expected: true),
    // Comparison: numeric, string-by-code-unit, and the null coercion
    // (ts:335-356).
    (expr: 'datum.n > datum.f', expected: true),
    (expr: "datum.s > 'a'", expected: true),
    (expr: "'10' < '9'", expected: true),
    (expr: 'datum.z >= 0', expected: true),
    (expr: 'datum.z > 0', expected: false),
    (expr: 'datum.arr == datum.arr', expected: true),
    // `&&` and `||` yield an OPERAND, not a boolean (ts:290-308). The falsy
    // left operand of `&&` comes back untouched, so a missing field yields
    // `undefined` — not `null`.
    (expr: 'datum.missing || 5', expected: 5),
    (expr: 'datum.n || 5', expected: 3),
    (expr: 'datum.missing && 5', expected: JsUndefined.instance),
    (expr: 'datum.n && 5', expected: 5),
    (expr: '!datum.missing', expected: true),
    (expr: '!datum.n', expected: false),
    // Member access, own properties only (ts:415-437).
    (expr: 'datum.obj.k', expected: 9),
    (expr: "datum.obj['k']", expected: 9),
    (expr: "datum['obj']['k']", expected: 9),
    (expr: 'datum.arr[0]', expected: 1),
    // `hasOwn` answers true for an array's `length` but the guard at ts:37
    // requires `typeof value === 'object'`, so a STRING has no readable
    // `length` — the trap a port over Dart's own `String.length` falls into.
    (expr: 'datum.arr.length', expected: 2),
    (expr: 'datum.s.length', expected: JsUndefined.instance),
    (expr: 'datum.arr[3]', expected: JsUndefined.instance),
    (expr: 'datum.obj.missing == null', expected: true),
    // The built-ins (ts:43-66).
    (expr: 'length(datum.arr)', expected: 2),
    (expr: 'length(datum.obj)', expected: 0),
    (expr: 'isArray(datum.arr)', expected: true),
    (expr: 'isDate(datum.n)', expected: false),
    (expr: 'isValid(datum.missing)', expected: false),
    (expr: 'toNumber(datum.s)', expected: double.nan),
    (expr: 'toString(datum.arr)', expected: '1,2'),
    (expr: 'toBoolean(datum.z)', expected: false),
    // `Math.round` is half-UP, not half-away-from-zero: the three negative
    // ties are where Dart's `num.round()` diverges.
    (expr: 'round(datum.f)', expected: 2),
    (expr: 'round(-datum.f)', expected: -1),
    (expr: 'round(-2.5)', expected: -2),
    (expr: 'round(-0.5)', expected: 0),
    (expr: 'abs(-datum.n)', expected: 3),
    (expr: 'sqrt(datum.n * 3)', expected: 3),
    (expr: 'min(datum.n, datum.f)', expected: 1.5),
    (expr: 'max(datum.n, datum.f)', expected: 3),
    (expr: 'pow(datum.n, 2)', expected: 9),
    // A built-in called with too few arguments binds the rest to `undefined`,
    // and `Math.min()`/`Math.max()` have their identities (ts:60-61).
    (expr: 'abs()', expected: double.nan),
    (expr: 'pow(2)', expected: double.nan),
    (expr: 'length()', expected: 0),
    (expr: 'min()', expected: double.infinity),
    (expr: 'max()', expected: double.negativeInfinity),
    // The ternary selects on truthiness and yields either branch's value
    // (ts:278-288).
    (expr: 'datum.n > 2 ? datum.s : datum.z', expected: 'x'),
    (expr: 'datum.n < 2 ? datum.s : datum.z', expected: null),
    (expr: '1 ? datum.missing : 2', expected: JsUndefined.instance),
  ];

  test('the matrix covers every row that was recorded', () {
    expect(
      rows.length,
      64,
      reason:
          'A row silently dropped from this table is a hole in the '
          'differential, so the count is pinned to the node run above.',
    );
  });

  for (final row in rows) {
    test('evaluates ${row.expr}', () {
      final actual = eval(row.expr);
      if (row.expected is double && (row.expected! as double).isNaN) {
        expect(
          (actual! as num).isNaN,
          isTrue,
          reason: '${row.expr} must be NaN, matching the node run.',
        );
        return;
      }
      expect(
        actual,
        row.expected,
        reason:
            '${row.expr} must equal ${row.expected} exactly — this value was '
            'recorded from a node run of the upstream '
            'VegaLiteExpressionEvaluator.',
      );
    });
  }

  group('security', () {
    // Every one of these is a real escape route in a JavaScript evaluator that
    // resolves free identifiers against the host scope. Upstream closes them
    // all at ts:475-477 before any lookup happens, and so does the port.
    const hostile = <String>[
      'constructor',
      '__proto__',
      'globalThis',
      'window',
      'process',
      'require',
      'eval',
      'Function',
      'this',
      'import',
    ];
    for (final name in hostile) {
      test('rejects the bare identifier $name', () {
        expect(
          () => evaluateVegaExpression(name, const <String, Object?>{}),
          throwsA(
            isA<VegaExpressionException>().having(
              (e) => e.message,
              'message',
              "Safe expression evaluator: unknown identifier '$name'",
            ),
          ),
          reason:
              'VegaLiteExpressionEvaluator.ts:475-477: ALLOWED_IDENTIFIERS is '
              "a closed set of 'datum' plus the 22 functions and 7 constants, "
              'and the node run throws this exact message for each of these.',
        );
      });
    }

    // Prototype-reaching property names. Upstream blocks these with `hasOwn`
    // (ts:37-38); Dart blocks them structurally, because a `Map` holds only
    // what was put in it. Either way the read yields `undefined`, which the
    // node run confirms for every name here.
    const inherited = <String>[
      'datum.constructor',
      'datum.__proto__',
      "datum['__proto__']",
      "datum['constructor']",
      'datum.valueOf',
      'datum.hasOwnProperty',
      'datum.toString',
      'datum.arr.map',
      'datum.s.charAt',
      // A chain THROUGH a prototype name: `undefined.x` is a TypeError in real
      // JavaScript but is `undefined` here, because ts:421 tests `hasOwn`
      // rather than dereferencing.
      'datum.__proto__.x',
      'datum.a.b.c',
    ];
    for (final expr in inherited) {
      test('$expr yields undefined rather than a prototype member', () {
        expect(
          evaluateVegaExpression(expr, const <String, Object?>{
            'a': 1,
            'arr': <Object?>[1, 2],
            's': 'x',
          }),
          same(JsUndefined.instance),
          reason:
              'VegaLiteExpressionEvaluator.ts:415-437 reads an own property or '
              'yields undefined; the node run returns undefined for $expr.',
        );
      });
    }

    test('a member expression cannot reach a prototype method', () {
      expect(
        evaluateVegaExpression(
          'datum.constructor == null',
          const <String, Object?>{'a': 1},
        ),
        true,
        reason:
            'datum.constructor is undefined, and `undefined == null` is true '
            '(ts:316-318) — so this proves the access yielded a nullish value '
            'rather than a callable. The plan asserted false here while its '
            'own justification argued true; the node run returns true.',
      );
    });

    test('an inherited method cannot be invoked', () {
      expect(
        () => evaluateVegaExpression(
          'datum.toString()',
          const <String, Object?>{},
        ),
        throwsA(
          isA<VegaExpressionException>().having(
            (e) => e.message,
            'message',
            'Safe expression evaluator: function calls are only allowed for '
                'built-in functions',
          ),
        ),
        reason:
            'VegaLiteExpressionEvaluator.ts:440-442: the value is undefined, '
            'not a function.',
      );
    });

    test('a datum value cannot be invoked', () {
      expect(
        () => evaluateVegaExpression('datum.a(1)', const <String, Object?>{
          'a': 1,
        }),
        throwsA(isA<VegaExpressionException>()),
        reason:
            'ts:440-442 gates the call on the VALUE being a built-in, so no '
            'spec-supplied datum entry is ever reachable as a callee.',
      );
    });

    test('a datum-supplied __proto__ key is an inert value', () {
      expect(
        evaluateVegaExpression('datum.__proto__.evil', const <String, Object?>{
          '__proto__': <String, Object?>{'evil': 1},
        }),
        1,
        reason:
            'A hostile spec can name a field `__proto__`; in Dart that is one '
            'more map key, so it reads back as data and pollutes nothing. The '
            'node run over an own `__proto__` property returns 1 too, and '
            "`({}).evil` stays undefined after it. 1 is the fixture's own "
            'value.',
      );
      expect(
        evaluateVegaExpression('datum.evil', const <String, Object?>{
          '__proto__': <String, Object?>{'evil': 1},
        }),
        same(JsUndefined.instance),
        reason:
            'The planted prototype is not consulted for an ordinary lookup — '
            'the pollution did not take.',
      );
    });

    test('a built-in does not leak its own source text', () {
      expect(
        evaluateVegaExpression('toString(round)', const <String, Object?>{}),
        '[object Object]',
        reason:
            'hardened, spec §5.2 exception 2: the node run returns the '
            "function's source, '(x)=>Math.round(x)'. Handing a spec author "
            'the implementation text of an internal is an information leak '
            'with no legitimate use, so jsToString renders a non-primitive '
            'opaquely instead.',
      );
    });

    test('assignment is not in the grammar', () {
      expect(
        () => evaluateVegaExpression('datum.a = 1', const <String, Object?>{
          'a': 0,
        }),
        throwsA(
          isA<VegaExpressionException>().having(
            (e) => e.message,
            'message',
            "Safe expression evaluator: unexpected character '=' at position 8",
          ),
        ),
        reason:
            "'=' is not in the single-character operator set at "
            'VegaLiteExpressionEvaluator.ts:203, and 8 is its index in this '
            'expression — the node run throws this exact message.',
      );
    });

    test('a deeply nested expression does not blow the stack', () {
      // 200 is the plan's depth; each level costs ten frames in this
      // single-pass parser (ternary down to primary), so this is ~2000 frames.
      final expr = '${'(' * 200}1${')' * 200}';
      expect(
        evaluateVegaExpression(expr, const <String, Object?>{}),
        1,
        reason:
            'A hostile spec can nest parentheses; 200 levels must still '
            'evaluate to the 1 at the centre.',
      );
    });

    test('a long unary chain past the ceiling is refused, not crashed', () {
      // Measured before the guard: 50,000 negations evaluated and 200,000 threw
      // a raw StackOverflowError, so `!` is the second unbounded path and it
      // does not pass through _parseExpression. One count per `!`.
      expect(
        () => evaluateVegaExpression(
          '${'!' * (kVegaMaxExpressionDepth + 1)}datum.a',
          const <String, Object?>{'a': 1},
        ),
        throwsA(
          isA<VegaExpressionException>().having(
            (e) => e.message,
            'message',
            'Safe expression evaluator: Maximum expression depth exceeded',
          ),
        ),
        reason:
            'the unary arm recurses into itself, so guarding only the grammar '
            'entry point would leave a 200,000-character negation chain able '
            'to take the frame down',
      );
    });

    test('nesting past the ceiling is refused, not crashed', () {
      // hardened, spec §5.2 exception 2: the JSON depth guard counts *object*
      // nesting, and an expression is one string value at JSON depth 3 — so
      // `{"transform": [{"calculate": "((((…1…))))"}]}` clears
      // `validateVegaJsonDepth` however deep the parentheses go. Measured on
      // this tree before the guard existed: 2,000 levels evaluated, 10,000
      // threw a raw `StackOverflowError` out of `_parsePrimary`, and because
      // `FluentVegaDeclarativeChart.build` catches only VegaSpecException and
      // VegaExpressionException it escaped `build()` and took the frame down.
      // Upstream has no counterpart guard — `VegaLiteExpressionEvaluator.ts`
      // recurses unbounded — so this is added rather than ported.
      final expr =
          '${'(' * (kVegaMaxExpressionDepth + 1)}1'
          '${')' * (kVegaMaxExpressionDepth + 1)}';
      expect(
        () => evaluateVegaExpression(expr, const <String, Object?>{}),
        throwsA(
          isA<VegaExpressionException>().having(
            (e) => e.message,
            'message',
            'Safe expression evaluator: Maximum expression depth exceeded',
          ),
        ),
        reason:
            'one level past the ceiling must surface as the same exception '
            'every other refusal does, so the widget renders its error body '
            'instead of throwing an Error no catch clause names',
      );
    });

    test('a long flat expression does not blow the stack', () {
      // 2000 terms: the additive loop is iterative, so depth stays constant
      // while length grows. 2001 is the recorded node result for 1 + 1*2000.
      expect(
        evaluateVegaExpression('1${'+1' * 2000}', const <String, Object?>{}),
        2001,
        reason:
            'ts:358-373 loops rather than recursing, so a two-thousand-term '
            'sum is bounded work; the node run gives 2001.',
      );
    });

    test('a long unary chain does not blow the stack', () {
      // 500 negations of a truthy value: an odd count, so the result is false.
      expect(
        evaluateVegaExpression('${'!' * 500}datum.a', const <String, Object?>{
          'a': 1,
        }),
        true,
        reason:
            'ts:395-399 recurses once per `!`; 500 must still evaluate, and '
            'an even count of negations restores truthiness — the node run '
            'gives true.',
      );
    });

    test('a long member chain does not blow the stack', () {
      // 500 hops, each of which misses and yields undefined.
      expect(
        evaluateVegaExpression('datum${'.a' * 500}', const <String, Object?>{
          'a': 1,
        }),
        same(JsUndefined.instance),
        reason:
            'ts:411-457 loops over postfix operators rather than recursing, '
            'so a five-hundred-hop chain is bounded work; the node run gives '
            'undefined.',
      );
    });
  });
}
