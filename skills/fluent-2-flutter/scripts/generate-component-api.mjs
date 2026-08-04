#!/usr/bin/env node

import { access, readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath, pathToFileURL } from 'node:url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const SKILL_DIR = path.resolve(SCRIPT_DIR, '..');
const REFERENCES_DIR = path.join(SKILL_DIR, 'references');
const COVERAGE_FILE = path.join(REFERENCES_DIR, 'widget-coverage.json');
const MANIFEST_FILE = path.join(REFERENCES_DIR, 'source-manifest.json');
const args = new Set(process.argv.slice(2));

for (const arg of args) {
  if (arg !== '--write') fail(`Unknown argument: ${arg}`);
}

function fail(message) {
  process.stderr.write(`ERROR: ${message}\n`);
  process.exit(1);
}

async function exists(target) {
  try {
    await access(target);
    return true;
  } catch {
    return false;
  }
}

async function walk(directory) {
  if (!(await exists(directory))) return [];
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const target = path.join(directory, entry.name);
    if (entry.isDirectory()) files.push(...(await walk(target)));
    if (entry.isFile() && entry.name.endsWith('.dart')) files.push(target);
  }
  return files;
}

async function isRepository(directory) {
  return (
    (await exists(path.join(directory, 'packages/fluent_2_core/lib'))) &&
    (await exists(path.join(directory, 'packages/fluent_2_web/lib')))
  );
}

async function findRepository() {
  const starts = [process.cwd(), path.resolve(SKILL_DIR, '../..')];
  const visited = new Set();
  for (const start of starts) {
    let current = path.resolve(start);
    while (!visited.has(current)) {
      visited.add(current);
      if (await isRepository(current)) return current;
      const parent = path.dirname(current);
      if (parent === current) break;
      current = parent;
    }
  }
  return null;
}

// Replace comments and string contents with spaces while preserving offsets and
// newlines. Structural scans can then balance Dart delimiters without being
// confused by examples, comments, interpolation, or literal punctuation.
function maskNonCode(source) {
  const output = [...source];
  let index = 0;
  let blockDepth = 0;
  let quote = null;
  let triple = false;
  let raw = false;

  const blank = (position) => {
    if (output[position] !== '\n' && output[position] !== '\r') {
      output[position] = ' ';
    }
  };

  while (index < source.length) {
    if (blockDepth > 0) {
      if (source.startsWith('/*', index)) {
        blank(index);
        blank(index + 1);
        blockDepth += 1;
        index += 2;
      } else if (source.startsWith('*/', index)) {
        blank(index);
        blank(index + 1);
        blockDepth -= 1;
        index += 2;
      } else {
        blank(index);
        index += 1;
      }
      continue;
    }

    if (quote !== null) {
      const terminator = triple ? quote.repeat(3) : quote;
      if (source.startsWith(terminator, index)) {
        for (let offset = 0; offset < terminator.length; offset += 1) {
          blank(index + offset);
        }
        index += terminator.length;
        quote = null;
        triple = false;
        raw = false;
      } else if (!raw && source[index] === '\\') {
        blank(index);
        if (index + 1 < source.length) blank(index + 1);
        index += 2;
      } else {
        blank(index);
        index += 1;
      }
      continue;
    }

    if (source.startsWith('//', index)) {
      while (index < source.length && source[index] !== '\n') {
        blank(index);
        index += 1;
      }
      continue;
    }
    if (source.startsWith('/*', index)) {
      blank(index);
      blank(index + 1);
      blockDepth = 1;
      index += 2;
      continue;
    }

    const rawPrefix =
      (source[index] === 'r' || source[index] === 'R') &&
      (source[index + 1] === "'" || source[index + 1] === '"');
    const quoteIndex = rawPrefix ? index + 1 : index;
    if (source[quoteIndex] === "'" || source[quoteIndex] === '"') {
      raw = rawPrefix;
      if (rawPrefix) blank(index);
      quote = source[quoteIndex];
      triple = source.startsWith(quote.repeat(3), quoteIndex);
      const length = triple ? 3 : 1;
      for (let offset = 0; offset < length; offset += 1) {
        blank(quoteIndex + offset);
      }
      index = quoteIndex + length;
      continue;
    }
    index += 1;
  }
  return output.join('');
}

function matchingDelimiter(masked, start, open, close) {
  if (masked[start] !== open) return -1;
  let depth = 0;
  for (let index = start; index < masked.length; index += 1) {
    if (masked[index] === open) depth += 1;
    if (masked[index] === close) {
      depth -= 1;
      if (depth === 0) return index;
    }
  }
  return -1;
}

function topLevelOffsets(masked) {
  const offsets = new Uint16Array(masked.length + 1);
  let depth = 0;
  for (let index = 0; index < masked.length; index += 1) {
    offsets[index] = depth;
    if (masked[index] === '{') depth += 1;
    if (masked[index] === '}') depth = Math.max(0, depth - 1);
  }
  offsets[masked.length] = depth;
  return offsets;
}

function normalizeCode(value) {
  const lines = value.replaceAll('\r\n', '\n').trim().split('\n');
  const indents = lines
    .filter((line) => line.trim().length > 0)
    .map((line) => line.match(/^\s*/)[0].length);
  const indent = indents.length === 0 ? 0 : Math.min(...indents);
  return lines.map((line) => line.slice(indent).trimEnd()).join('\n');
}

function markdownCell(value) {
  return String(value ?? '')
    .replaceAll('|', '\\|')
    .replaceAll('\n', '<br>')
    .replace(/\s+/g, ' ')
    .trim();
}

function docsBefore(source, offset) {
  const before = source.slice(0, offset);
  const lines = before.split('\n');
  const docs = [];
  let index = lines.length - 1;
  while (index >= 0 && lines[index].trim().length === 0) index -= 1;
  while (index >= 0 && lines[index].trim().startsWith('///')) {
    docs.unshift(lines[index].trim().replace(/^\/\/\/ ?/, ''));
    index -= 1;
  }
  return docs.join('\n').trim();
}

function firstParagraph(documentation) {
  if (!documentation) return '';
  const paragraphs = documentation.split(/\n\s*\n|\n(?=##?\s)/);
  return paragraphs[0]
    .split('\n')
    .map((line) => line.trim())
    .join(' ')
    .trim();
}

function discoverDefinitions(source, file, repoDir) {
  const masked = maskNonCode(source);
  const definitions = [];
  const expression = /\b(class|enum)\s+(Fluent[A-Za-z0-9_]+|Icon|Image|Text)\b/g;
  for (const match of masked.matchAll(expression)) {
    const braceStart = masked.indexOf('{', match.index + match[0].length);
    if (braceStart < 0) continue;
    const braceEnd = matchingDelimiter(masked, braceStart, '{', '}');
    if (braceEnd < 0) continue;
    const header = source.slice(match.index, braceStart).trim();
    const genericMatch = header.match(
      new RegExp(`${match[2]}\\s*(<[^>{}]+>)`),
    );
    const baseMatch = header.match(/\bextends\s+(Fluent[A-Za-z0-9_]+)/);
    definitions.push({
      kind: match[1],
      name: match[2],
      generic: genericMatch?.[1] ?? '',
      baseName: baseMatch?.[1] ?? null,
      file,
      relativeFile: file.includes('/packages/flutter/lib/')
        ? `package:flutter/${file.split('/packages/flutter/lib/')[1]}`
        : path.relative(repoDir, file),
      source,
      masked,
      declarationStart: match.index,
      braceStart,
      braceEnd,
      documentation: docsBefore(source, match.index),
    });
  }
  return definitions;
}

function extractFields(definition) {
  if (definition.kind !== 'class') return [];
  const bodyStart = definition.braceStart + 1;
  const rawBody = definition.source.slice(bodyStart, definition.braceEnd);
  const maskedBody = definition.masked.slice(bodyStart, definition.braceEnd);
  const depths = topLevelOffsets(maskedBody);
  const fields = [];
  const expression = /\b(?:late\s+)?final\s+/g;
  for (const match of maskedBody.matchAll(expression)) {
    if (depths[match.index] !== 0) continue;
    let round = 0;
    let square = 0;
    let angle = 0;
    let end = -1;
    for (let index = match.index + match[0].length; index < maskedBody.length; index += 1) {
      const char = maskedBody[index];
      if (char === '(') round += 1;
      if (char === ')') round -= 1;
      if (char === '[') square += 1;
      if (char === ']') square -= 1;
      if (char === '<') angle += 1;
      if (char === '>') angle = Math.max(0, angle - 1);
      if (char === ';' && round === 0 && square === 0 && angle === 0) {
        end = index;
        break;
      }
    }
    if (end < 0) continue;
    const declaration = rawBody.slice(match.index, end + 1);
    const cleaned = declaration
      .replace(/^\s*(?:late\s+)?final\s+/, '')
      .replace(/;\s*$/, '')
      .trim();
    const nameMatch = cleaned.match(/([A-Za-z_]\w*)\s*$/);
    if (!nameMatch || nameMatch[1].startsWith('_')) continue;
    const name = nameMatch[1];
    const type = cleaned.slice(0, nameMatch.index).trim();
    if (!type || type.includes('=')) continue;
    const absoluteOffset = bodyStart + match.index;
    fields.push({
      name,
      type: normalizeCode(type).replace(/\s+/g, ' '),
      documentation: docsBefore(definition.source, absoluteOffset),
    });
  }
  return fields;
}

function fieldsIncludingInherited(definition, typeIndex, visited = new Set()) {
  if (visited.has(definition.name)) return [];
  visited.add(definition.name);
  const inherited = definition.baseName
    ? typeIndex.get(definition.baseName)
    : null;
  const fields = inherited
    ? fieldsIncludingInherited(inherited, typeIndex, visited)
    : [];
  const byName = new Map(fields.map((field) => [field.name, field]));
  for (const field of extractFields(definition)) byName.set(field.name, field);
  return [...byName.values()];
}

function extractConstructors(definition) {
  if (definition.kind !== 'class') return [];
  const bodyStart = definition.braceStart + 1;
  const rawBody = definition.source.slice(bodyStart, definition.braceEnd);
  const maskedBody = definition.masked.slice(bodyStart, definition.braceEnd);
  const depths = topLevelOffsets(maskedBody);
  const escapedName = definition.name.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  const expression = new RegExp(
    `^[ \\t]*(?:(const|factory)\\s+)?${escapedName}(?:\\.([A-Za-z]\\w*))?\\s*\\(`,
    'gm',
  );
  const constructors = [];
  for (const match of maskedBody.matchAll(expression)) {
    if (depths[match.index] !== 0) continue;
    if (match[2]?.startsWith('_')) continue;
    const open = maskedBody.indexOf('(', match.index);
    const close = matchingDelimiter(maskedBody, open, '(', ')');
    if (close < 0) continue;
    if (!match[1]) {
      let next = close + 1;
      while (next < maskedBody.length && /\s/.test(maskedBody[next])) next += 1;
      if (
        !match[2] ||
        !(
          maskedBody[next] === ':' ||
          maskedBody[next] === '{' ||
          maskedBody.startsWith('=>', next)
        )
      ) {
        continue;
      }
    }
    const signature = normalizeCode(rawBody.slice(match.index, close + 1));
    constructors.push({
      name: match[2] ? `${definition.name}.${match[2]}` : definition.name,
      signature: `${signature};`,
      open,
      close,
      rawParameters: rawBody.slice(open + 1, close),
      maskedParameters: maskedBody.slice(open + 1, close),
    });
  }
  return constructors;
}

function stripOuterParameterGroup(raw, masked) {
  let start = 0;
  let end = masked.length;
  while (start < end && /\s/.test(masked[start])) start += 1;
  while (end > start && /\s/.test(masked[end - 1])) end -= 1;
  const open = masked[start];
  const close = open === '{' ? '}' : open === '[' ? ']' : null;
  if (close !== null && matchingDelimiter(masked, start, open, close) === end - 1) {
    return {
      raw: raw.slice(start + 1, end - 1),
      masked: masked.slice(start + 1, end - 1),
      optionalGroup: open === '[',
      namedGroup: open === '{',
    };
  }
  return {
    raw: raw.slice(start, end),
    masked: masked.slice(start, end),
    optionalGroup: false,
    namedGroup: false,
  };
}

function splitTopLevel(raw, masked, separator = ',') {
  const values = [];
  let start = 0;
  const stack = [];
  const pairs = { '(': ')', '[': ']', '{': '}', '<': '>' };
  for (let index = 0; index < masked.length; index += 1) {
    const char = masked[index];
    if (pairs[char]) stack.push(pairs[char]);
    else if (stack.at(-1) === char) stack.pop();
    else if (char === separator && stack.length === 0) {
      values.push({ raw: raw.slice(start, index), masked: masked.slice(start, index) });
      start = index + 1;
    }
  }
  values.push({ raw: raw.slice(start), masked: masked.slice(start) });
  return values.filter((value) => value.masked.trim().length > 0);
}

function splitConstructorParameters(
  raw,
  masked,
  inheritedGroup = { namedGroup: false, optionalGroup: false },
) {
  const grouped = stripOuterParameterGroup(raw, masked);
  const group = {
    namedGroup: inheritedGroup.namedGroup || grouped.namedGroup,
    optionalGroup: inheritedGroup.optionalGroup || grouped.optionalGroup,
  };
  const parts = splitTopLevel(grouped.raw, grouped.masked);
  const output = [];
  for (const part of parts) {
    const nested = stripOuterParameterGroup(part.raw, part.masked);
    if (nested.namedGroup || nested.optionalGroup) {
      output.push(
        ...splitConstructorParameters(part.raw, part.masked, group),
      );
    } else {
      output.push({ ...part, ...group });
    }
  }
  return output;
}

function topLevelEquals(masked) {
  const stack = [];
  const pairs = { '(': ')', '[': ']', '{': '}', '<': '>' };
  for (let index = 0; index < masked.length; index += 1) {
    const char = masked[index];
    if (pairs[char]) stack.push(pairs[char]);
    else if (stack.at(-1) === char) stack.pop();
    else if (
      char === '=' &&
      stack.length === 0 &&
      masked[index - 1] !== '=' &&
      masked[index + 1] !== '=' &&
      masked[index + 1] !== '>'
    ) {
      return index;
    }
  }
  return -1;
}

const COMMON_PARAMETER_PURPOSES = new Map([
  ['key', 'Flutter widget identity.'],
  ['child', 'The widget subtree rendered or affected by this API.'],
  ['items', 'The ordered component items to render.'],
  ['maxDisplayedItems', 'Maximum number of items shown before overflow behavior is used.'],
  ['value', 'The value represented, selected, or supplied by this API.'],
  ['color', 'The color applied by this constructor or theme factory.'],
  ['brightness', 'The light or dark brightness used to derive theme values.'],
  ['brand', 'The Fluent brand ramp used to derive semantic theme colors.'],
  ['platform', 'The target platform whose interaction and visual defaults are applied.'],
  ['fontPlatform', 'The target platform used to choose the Fluent typography family and metrics.'],
  ['textScaleFactor', 'Legacy multiplier applied to the generated typography scale. Prefer current MediaQuery text scaling in widget code.'],
  ['src', 'Network URL used as the image source.'],
  ['file', 'Local file used as the image source.'],
  ['bytes', 'Encoded image bytes used as the image source.'],
  ['name', 'Asset name used to locate the image resource.'],
  ['scale', 'Scale factor used when decoding and laying out the image.'],
  ['headers', 'Optional HTTP headers sent while loading a network image.'],
  ['cacheWidth', 'Requested decoded-image cache width in physical pixels.'],
  ['cacheHeight', 'Requested decoded-image cache height in physical pixels.'],
  ['bundle', 'Asset bundle from which the image resource is loaded.'],
  ['package', 'Package namespace containing the image asset.'],
  ['webHtmlElementStrategy', 'Flutter Web strategy for rendering the network image with an HTML element.'],
]);

function fallbackParameterPurpose(name) {
  if (COMMON_PARAMETER_PURPOSES.has(name)) {
    return COMMON_PARAMETER_PURPOSES.get(name);
  }
  if (/^(?:display|largeTitle|title\d|subtitle\d|body\d|caption\d)/.test(name)) {
    return `Typography style assigned to the ${name} Fluent type ramp.`;
  }
  return 'Public constructor parameter; follow the exact signature and source contract.';
}

function constructorParameters(constructor, fields, inheritedDefaults = new Map()) {
  const fieldMap = new Map(fields.map((field) => [field.name, field]));
  const parts = splitConstructorParameters(
    constructor.rawParameters,
    constructor.maskedParameters,
  );
  return parts.map((part) => {
    const equals = topLevelEquals(part.masked);
    const left = (equals < 0 ? part.raw : part.raw.slice(0, equals)).trim();
    const explicitDefault = equals < 0 ? null : part.raw.slice(equals + 1).trim();
    const binding = left.match(/\b(?:this|super)\.([A-Za-z_]\w*)\b/);
    const nameMatch = binding ?? left.match(/([A-Za-z_]\w*)\s*$/);
    const name = nameMatch?.[1] ?? normalizeCode(left);
    const field = fieldMap.get(name);
    const explicitTypeCandidate = binding
      ? left
          .slice(0, binding.index)
          .replace(/^required\s+/, '')
          .replace(/^covariant\s+/, '')
          .trim()
      : '';
    const explicitType = explicitTypeCandidate.includes('@')
      ? ''
      : explicitTypeCandidate;
    let type = explicitType || field?.type;
    if (!type && binding?.[0] === 'super.key') type = 'Key?';
    if (!type && binding?.[0] === 'super.child') type = 'Widget';
    if (!type) {
      type = left
        .replace(/^required\s+/, '')
        .replace(/^covariant\s+/, '')
        .replace(/\b(?:this|super)\.[A-Za-z_]\w*\b/, '')
        .replace(new RegExp(`\\b${name}\\s*$`), '')
        .trim();
    }
    if (!type) type = 'inherited';
    const requiredKeyword = /^\s*required\b/.test(left);
    const required = requiredKeyword || (!part.namedGroup && !part.optionalGroup);
    const defaultValue =
      explicitDefault ??
      (binding?.[0].startsWith('super.') ? inheritedDefaults.get(name) : null);
    const fallbackPurpose = fallbackParameterPurpose(name);
    return {
      name,
      type: normalizeCode(type).replace(/\s+/g, ' '),
      required,
      defaultValue:
        defaultValue ?? (required ? '—' : part.optionalGroup ? 'positional default' : 'null'),
      purpose: firstParagraph(field?.documentation) || fallbackPurpose,
      documentation: field?.documentation ?? '',
    };
  });
}

function inheritedConstructorDefaults(definition, typeIndex, visited = new Set()) {
  if (!definition.baseName || visited.has(definition.name)) return new Map();
  visited.add(definition.name);
  const base = typeIndex.get(definition.baseName);
  if (!base) return new Map();
  const inherited = inheritedConstructorDefaults(base, typeIndex, visited);
  const constructor = extractConstructors(base).find(
    (candidate) => candidate.name === base.name,
  );
  if (!constructor) return inherited;
  const parameters = constructorParameters(
    constructor,
    fieldsIncludingInherited(base, typeIndex),
    inherited,
  );
  for (const parameter of parameters) {
    if (!parameter.required && parameter.defaultValue !== 'positional default') {
      inherited.set(parameter.name, parameter.defaultValue);
    }
  }
  return inherited;
}

function enumValues(definition) {
  if (definition.kind !== 'enum') return [];
  const bodyStart = definition.braceStart + 1;
  const rawBody = definition.source.slice(bodyStart, definition.braceEnd);
  const maskedBody = definition.masked.slice(bodyStart, definition.braceEnd);
  let valuesEnd = maskedBody.length;
  const stack = [];
  const pairs = { '(': ')', '[': ']', '{': '}', '<': '>' };
  for (let index = 0; index < maskedBody.length; index += 1) {
    const char = maskedBody[index];
    if (pairs[char]) stack.push(pairs[char]);
    else if (stack.at(-1) === char) stack.pop();
    else if (char === ';' && stack.length === 0) {
      valuesEnd = index;
      break;
    }
  }
  return splitTopLevel(
    rawBody.slice(0, valuesEnd),
    maskedBody.slice(0, valuesEnd),
  )
    .map((value) => value.masked.trim().match(/^([A-Za-z]\w*)/)?.[1])
    .filter(Boolean);
}

function fluentTypeNames(value) {
  return [...String(value).matchAll(/\b(Fluent[A-Za-z0-9_]+)\b/g)].map(
    (match) => match[1],
  );
}

function officialSourceFor(manifest, slug) {
  return manifest.categories.webCore.find((url) =>
    url.includes(`/core/${slug}/usage/`),
  );
}

function componentTitle(slug) {
  const special = new Map([
    ['avatargroup', 'Avatar group'],
    ['fluentprovider', 'Fluent provider'],
    ['infolabel', 'Info label'],
    ['messagebar', 'Message bar'],
    ['progressbar', 'Progress bar'],
    ['radiogroup', 'Radio group'],
    ['searchbox', 'Search box'],
    ['tablist', 'Tab list'],
    ['tagpicker', 'Tag picker'],
    ['textarea', 'Text area'],
  ]);
  return special.get(slug) ?? `${slug[0].toUpperCase()}${slug.slice(1)}`;
}

function statusExplanation(entry) {
  if (entry.status === 'implemented') {
    return 'A purpose-built public Flutter widget exists. Use only the constructors documented below.';
  }
  if (entry.status === 'compose') {
    return entry.widgets.length > 0
      ? 'There is no one-to-one Fluent widget. Compose the mapped API deliberately and preserve the official semantics.'
      : 'There is no one-to-one Fluent widget. Use the Flutter primitive and Fluent tokens described in the design guidance; do not invent a class.';
  }
  return 'No safe Flutter equivalent exists in this checkout. Report or implement the gap explicitly; do not invent a constructor.';
}

function renderParameterTable(parameters) {
  const rows = parameters.map(
    (parameter) =>
      `| \`${markdownCell(parameter.name)}\` | \`${markdownCell(parameter.type)}\` | ${
        parameter.required ? 'Yes' : 'No'
      } | ${
        parameter.defaultValue === '—'
          ? '—'
          : `\`${markdownCell(parameter.defaultValue)}\``
      } | ${markdownCell(parameter.purpose)} |`,
  );
  return [
    '| Field | Type | Required | Default | Purpose |',
    '| --- | --- | --- | --- | --- |',
    ...rows,
  ].join('\n');
}

function renderClassApi(definition, headingLevel, typeIndex) {
  const heading = '#'.repeat(headingLevel);
  const ownFields = extractFields(definition);
  const fields = fieldsIncludingInherited(definition, typeIndex);
  const inheritedDefaults = inheritedConstructorDefaults(definition, typeIndex);
  const constructors = extractConstructors(definition);
  const output = [`${heading} \`${definition.name}${definition.generic}\``];
  const summary = firstParagraph(definition.documentation);
  if (summary) output.push('', summary);
  output.push('', `Source: \`${definition.relativeFile}\``);

  if (constructors.length === 0) {
    output.push('', 'No public generative constructor is declared on this type.');
  }
  for (const constructor of constructors) {
    const parameters = constructorParameters(
      constructor,
      fields,
      inheritedDefaults,
    );
    output.push(
      '',
      `${heading}# Constructor: \`${constructor.name}\``,
      '',
      '```dart',
      constructor.signature,
      '```',
    );
    if (parameters.length > 0) output.push('', renderParameterTable(parameters));
  }

  const operational = ownFields.filter((field) =>
    /^(?:on[A-Z]|value|selected|checked|enabled|open|expanded|controller|focusNode|autofocus|semanticLabel)/.test(
      field.name,
    ),
  );
  if (operational.length > 0) {
    output.push('', `${heading}# State, callback, and accessibility fields`, '');
    for (const field of operational) {
      output.push(
        `- \`${field.name}\` (\`${field.type}\`): ${markdownCell(
          firstParagraph(field.documentation) ||
            'Use according to the exact constructor contract above.',
        )}`,
      );
    }
  }
  return output.join('\n');
}

function extractRecompositionFunctions(definitions) {
  const functions = new Map();
  for (const definition of definitions) {
    const depths = topLevelOffsets(definition.masked);
    const expression =
      /^[ \t]*(?:[A-Za-z_][A-Za-z0-9_<>,?. ]*?)\s+((?:resolve|build)Fluent[A-Za-z0-9_]+)\s*\(/gm;
    for (const match of definition.masked.matchAll(expression)) {
      if (depths[match.index] !== 0) continue;
      const open = definition.masked.indexOf('(', match.index);
      const close = matchingDelimiter(definition.masked, open, '(', ')');
      if (close < 0) continue;
      const lineStart = definition.source.lastIndexOf('\n', match.index) + 1;
      const signature = normalizeCode(
        definition.source.slice(lineStart, close + 1),
      );
      functions.set(match[1], `${signature};`);
    }
  }
  return [...functions.values()].sort();
}

function findUsageExample(widgetNames, usageFiles, fileCache, repoDir) {
  const orderedFiles = [...usageFiles].sort((a, b) => {
    const aStory = a.includes('/example/') ? 0 : 1;
    const bStory = b.includes('/example/') ? 0 : 1;
    return aStory - bStory || a.localeCompare(b);
  });
  for (const widgetName of widgetNames) {
    const escaped = widgetName.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
    const expression = new RegExp(`\\b${escaped}(?:\\.[A-Za-z]\\w*)?\\s*\\(`, 'g');
    for (const file of orderedFiles) {
      const cached = fileCache.get(file);
      if (!cached || !cached.source.includes(widgetName)) continue;
      for (const match of cached.masked.matchAll(expression)) {
        const open = cached.masked.indexOf('(', match.index);
        const close = matchingDelimiter(cached.masked, open, '(', ')');
        if (close < 0) continue;
        const raw = cached.source.slice(match.index, close + 1);
        if (raw.length > 2200) continue;
        return {
          code: normalizeCode(raw),
          source: path.relative(repoDir, file),
        };
      }
    }
  }
  return null;
}

function renderComponent(entry, manifest, typeIndex, usageFiles, fileCache, repoDir) {
  const title = componentTitle(entry.slug);
  const officialSource = officialSourceFor(manifest, entry.slug);
  const mappedNames = [
    ...entry.widgets,
    ...(entry.themes ?? []),
    ...(entry.externalWidgets ?? []),
  ];
  const definitions = mappedNames.map((name) => typeIndex.get(name)).filter(Boolean);
  const missingDefinitions = mappedNames.filter((name) => !typeIndex.has(name));
  if (missingDefinitions.length > 0) {
    throw new Error(
      `${entry.slug} maps unknown Flutter types: ${missingDefinitions.join(', ')}.`,
    );
  }

  const relatedNames = new Set();
  for (const name of entry.relatedTypes ?? []) relatedNames.add(name);
  for (const definition of definitions) {
    const fields = extractFields(definition);
    for (const field of fields) {
      for (const name of fluentTypeNames(field.type)) relatedNames.add(name);
    }
    const themeName = `${definition.name}Theme`;
    if (typeIndex.has(themeName)) relatedNames.add(themeName);
    for (const candidate of typeIndex.values()) {
      if (
        candidate.name.startsWith(definition.name) &&
        /(?:BaseState|State|Painter|Partition|Intent|Controller|Scope|EdgeColors)$/.test(
          candidate.name,
        )
      ) {
        relatedNames.add(candidate.name);
      }
    }
  }
  for (const name of mappedNames) relatedNames.delete(name);
  const related = [...relatedNames]
    .map((name) => typeIndex.get(name))
    .filter(Boolean)
    .sort((a, b) => a.name.localeCompare(b.name));

  const matchingUsageFiles =
    (entry.externalWidgets?.length ?? 0) > 0
      ? []
      : usageFiles.filter((file) =>
          mappedNames.some((name) => fileCache.get(file)?.source.includes(name)),
        );
  const tests = matchingUsageFiles
    .filter((file) => file.includes('/test/'))
    .map((file) => path.relative(repoDir, file));
  const stories = matchingUsageFiles
    .filter((file) => file.includes('/example/'))
    .map((file) => path.relative(repoDir, file));
  const example = findUsageExample(
    mappedNames,
    matchingUsageFiles,
    fileCache,
    repoDir,
  );
  const recompositionFunctions = extractRecompositionFunctions(definitions);
  // Behavior the extractor cannot see. A constructor signature states that
  // `onChanged` exists; it cannot state that arrow keys never reach it. These
  // are hand-audited against the official usage page and the Dart source, and
  // live in widget-coverage.json so one file remains the mapping's truth.
  const notes = entry.notes ?? [];

  const output = [
    `# ${title}: Flutter API and field definitions`,
    '',
    'Generated by `scripts/generate-component-api.mjs`. Do not edit this file',
    'manually; refresh it from the current Dart source and review the diff.',
    '',
    `Official guidance: ${officialSource}`,
    '',
    `Design decisions and best practices: [${entry.reference}](./${entry.reference})`,
    '',
    '## Contents',
    '',
    '- Mapping and API rule',
    ...(notes.length > 0 ? ['- Behavior and parity notes'] : []),
    '- Widget constructors and fields',
    '- Related public types',
    '- Verified usage',
    '- Source and test evidence',
    '',
    '## Mapping and API rule',
    '',
    `Status: **${entry.status}**. ${statusExplanation(entry)}`,
    '',
    mappedNames.length > 0
      ? `Mapped Flutter API: ${mappedNames.map((name) => `\`${name}\``).join(', ')}.`
      : 'Mapped Flutter API: none.',
    '',
    'The signatures below are extracted from the checked-out Dart source. React',
    'properties from the Microsoft site are design evidence, not Flutter fields.',
  ];

  if (notes.length > 0) {
    output.push(
      '',
      '## Behavior and parity notes',
      '',
      'Hand-audited behavior that no constructor signature can express. Treat a',
      'documented gap as a real gap: do not describe it as working, and do not',
      'work around it by inventing an API.',
      '',
      ...notes.map((note) => `- ${note}`),
    );
  }

  if (definitions.length === 0) {
    output.push(
      '',
      '## Widget constructors and fields',
      '',
      entry.status === 'missing'
        ? 'No constructor can be documented because the component is not implemented.'
        : 'No dedicated constructor exists. Follow the linked composition guidance.',
    );
  } else {
    output.push('', '## Widget constructors and fields');
    for (const definition of definitions) {
      output.push('', renderClassApi(definition, 3, typeIndex));
    }
  }

  output.push('', '## Related public types');
  if (related.length === 0) {
    output.push('', 'No component-specific public Fluent types are referenced by these fields.');
  } else {
    for (const definition of related) {
      if (definition.kind === 'enum') {
        const values = enumValues(definition);
        output.push(
          '',
          `### \`${definition.name}\``,
          '',
          firstParagraph(definition.documentation) || 'Public component enum.',
          '',
          `Source: \`${definition.relativeFile}\``,
          '',
          '```dart',
          `enum ${definition.name} {`,
          ...values.map((value) => `  ${value},`),
          '}',
          '```',
        );
      } else {
        output.push('', renderClassApi(definition, 3, typeIndex));
      }
    }
  }

  if (recompositionFunctions.length > 0) {
    output.push(
      '',
      '## Advanced public recomposition functions',
      '',
      'Use these only when the complete widget/style/theme composition cannot',
      'meet the requirement. Preserve semantics, focus, states, and motion.',
      '',
      '```dart',
      recompositionFunctions.join('\n\n'),
      '```',
    );
  }

  output.push('', '## Verified usage');
  if (example) {
    output.push(
      '',
      `Checked-in usage excerpt from \`${example.source}\`:`,
      '',
      '```dart',
      example.code,
      '```',
      '',
      'This excerpt verifies current constructor names. It may depend on local',
      'variables or surrounding story/test setup; inspect the cited file before',
      'copying it into a standalone application.',
    );
  } else {
    output.push(
      '',
      'No dedicated checked-in constructor excerpt is available. Use the exact',
      'signatures above and verify any new example with Dart analysis and a widget test.',
    );
  }

  output.push('', '## Source and test evidence', '');
  const sourcePaths = [...new Set(definitions.map((definition) => definition.relativeFile))];
  if (sourcePaths.length > 0) {
    output.push(`- Implementation: ${sourcePaths.map((value) => `\`${value}\``).join(', ')}`);
  }
  if (tests.length > 0) {
    output.push(`- Tests: ${tests.slice(0, 12).map((value) => `\`${value}\``).join(', ')}`);
  }
  if (stories.length > 0) {
    output.push(`- Stories: ${stories.slice(0, 12).map((value) => `\`${value}\``).join(', ')}`);
  }
  output.push(
    `- Official usage: ${officialSource}`,
    `- Design decisions: \`references/${entry.reference}\``,
    '',
    'If source and this snapshot differ, stop and run',
    '`node scripts/generate-component-api.mjs --write`, review the diff, and',
    're-run the bundled validators before generating Flutter code.',
  );
  return `${output.join('\n')}\n`;
}

try {
  const repoDir = await findRepository();
  const coverage = JSON.parse(await readFile(COVERAGE_FILE, 'utf8'));
  const manifest = JSON.parse(await readFile(MANIFEST_FILE, 'utf8'));
  if (repoDir === null) {
    if (args.has('--write')) {
      throw new Error('--write requires a fluent_2 source checkout.');
    }
    for (const entry of coverage.officialWebCore) {
      const file = path.join(REFERENCES_DIR, `api-${entry.slug}.md`);
      const markdown = await readFile(file, 'utf8');
      const source = officialSourceFor(manifest, entry.slug);
      if (!markdown.includes(source)) {
        throw new Error(`${path.basename(file)} is missing ${source}.`);
      }
      if (!markdown.includes(`Status: **${entry.status}**`)) {
        throw new Error(`${path.basename(file)} has stale mapping status.`);
      }
      for (const note of entry.notes ?? []) {
        if (!markdown.includes(note)) {
          throw new Error(`${path.basename(file)} is missing a parity note.`);
        }
      }
      for (const widget of entry.widgets) {
        if (!markdown.includes(`\`${widget}\``)) {
          throw new Error(`${path.basename(file)} is missing ${widget}.`);
        }
      }
      for (const theme of entry.themes ?? []) {
        if (!markdown.includes(`\`${theme}\``)) {
          throw new Error(`${path.basename(file)} is missing ${theme}.`);
        }
      }
      for (const widget of entry.externalWidgets ?? []) {
        if (!markdown.includes(`\`${widget}\``)) {
          throw new Error(`${path.basename(file)} is missing ${widget}.`);
        }
      }
      if (
        (entry.status === 'implemented' || (entry.externalWidgets?.length ?? 0) > 0) &&
        !markdown.includes('| Field | Type | Required | Default | Purpose |')
      ) {
        throw new Error(`${path.basename(file)} has no constructor field table.`);
      }
    }
    process.stdout.write(
      `Validated ${coverage.officialWebCore.length} component API references in snapshot mode.\n`,
    );
    process.exit(0);
  }
  const libDirectories = [
    path.join(repoDir, 'packages/fluent_2_core/lib'),
    path.join(repoDir, 'packages/fluent_2_web/lib'),
    path.join(repoDir, 'packages/fluent_2_mobile/lib'),
  ];
  const packageConfigFile = path.join(repoDir, '.dart_tool/package_config.json');
  if (await exists(packageConfigFile)) {
    const packageConfig = JSON.parse(await readFile(packageConfigFile, 'utf8'));
    const flutterPackage = packageConfig.packages?.find(
      (entry) => entry.name === 'flutter',
    );
    if (flutterPackage) {
      const flutterRoot = fileURLToPath(
        new URL(flutterPackage.rootUri, pathToFileURL(packageConfigFile)),
      );
      libDirectories.push(
        path.join(flutterRoot, 'lib/src/widgets/icon.dart'),
        path.join(flutterRoot, 'lib/src/widgets/image.dart'),
        path.join(flutterRoot, 'lib/src/widgets/text.dart'),
      );
    }
  }
  const dartFiles = [];
  for (const target of libDirectories) {
    if ((await exists(target)) && path.extname(target) === '.dart') {
      dartFiles.push(target);
    } else {
      dartFiles.push(...(await walk(target)));
    }
  }
  const typeIndex = new Map();
  for (const file of dartFiles) {
    const source = await readFile(file, 'utf8');
    for (const definition of discoverDefinitions(source, file, repoDir)) {
      if (!typeIndex.has(definition.name)) typeIndex.set(definition.name, definition);
    }
  }

  const usageFiles = (
    await Promise.all([
      walk(path.join(repoDir, 'packages/fluent_2_web/example/lib')),
      walk(path.join(repoDir, 'packages/fluent_2_web/test')),
      walk(path.join(repoDir, 'packages/fluent_2_core/test')),
      walk(path.join(repoDir, 'packages/fluent_2_mobile/test')),
    ])
  ).flat();
  const fileCache = new Map();
  for (const file of usageFiles) {
    const source = await readFile(file, 'utf8');
    fileCache.set(file, { source, masked: maskNonCode(source) });
  }

  const generated = new Map();
  for (const entry of coverage.officialWebCore) {
    const output = renderComponent(
      entry,
      manifest,
      typeIndex,
      usageFiles,
      fileCache,
      repoDir,
    );
    generated.set(path.join(REFERENCES_DIR, `api-${entry.slug}.md`), output);
  }

  const stale = [];
  for (const [file, output] of generated) {
    if (args.has('--write')) {
      await writeFile(file, output);
      continue;
    }
    if (!(await exists(file)) || (await readFile(file, 'utf8')) !== output) {
      stale.push(path.basename(file));
    }
  }
  if (stale.length > 0) {
    throw new Error(
      `Component API snapshots are missing or stale: ${stale.join(', ')}. ` +
        'Run with --write and review the diff.',
    );
  }
  process.stdout.write(
    `${args.has('--write') ? 'Wrote' : 'Validated'} ${generated.size} ` +
      `component API references from ${typeIndex.size} public API types.\n`,
  );
} catch (error) {
  fail(error.message);
}
