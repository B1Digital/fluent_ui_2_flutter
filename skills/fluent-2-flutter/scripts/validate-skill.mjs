#!/usr/bin/env node

import { readdir, readFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const SKILL_DIR = path.resolve(SCRIPT_DIR, '..');
const SKILL_FILE = path.join(SKILL_DIR, 'SKILL.md');
const DESIGN_REFERENCES = new Map([
  [
    'design-color.md',
    {
      source: 'https://fluent2.microsoft.design/color/',
      sections: ['### Neutral', '### Shared', '### Brand'],
    },
  ],
  [
    'design-elevation.md',
    {
      source: 'https://fluent2.microsoft.design/elevation/',
      sections: ['## Model depth with shadow and light', '## Use the elevation ramp', '## Handle colored surfaces'],
    },
  ],
  [
    'design-iconography.md',
    {
      source: 'https://fluent2.microsoft.design/iconography/',
      sections: ['### System icons', '### Product launch icons', '### File type icons', '## Apply icon construction rules'],
    },
  ],
  [
    'design-layout.md',
    {
      source: 'https://fluent2.microsoft.design/layout/',
      sections: ['## Use spacing and proximity deliberately', '## Build responsive structure', '## Reflow instead of shrink'],
    },
  ],
  [
    'design-material.md',
    {
      source: 'https://fluent2.microsoft.design/material/',
      sections: ['## Solid', '## Acrylic', '## Mica', '## Smoke'],
    },
  ],
  [
    'design-motion.md',
    {
      source: 'https://fluent2.microsoft.design/motion/',
      sections: ['## Apply the four motion principles', '## Choose duration and easing', '## Use the four common transition families', '## Choreograph related motion', '## Make motion accessible'],
    },
  ],
  [
    'design-shapes.md',
    {
      source: 'https://fluent2.microsoft.design/shapes/',
      sections: ['## Use the four forms', '## Map the official radius roles correctly', '## Apply strokes'],
    },
  ],
  [
    'design-typography.md',
    {
      source: 'https://fluent2.microsoft.design/typography/',
      sections: ['## Use the platform font stack', '## Use the semantic type ramp', '## Compose text correctly'],
    },
  ],
]);
const UX_REFERENCES = new Map([
  [
    'ux-accessibility.md',
    {
      source: 'https://fluent2.microsoft.design/accessibility/',
      sections: [
        '## Structure, hierarchy, and navigation',
        '## Keyboard and assistive technology',
        '## Color and contrast',
        '## Responsive layouts',
        '## Media and alternatives',
        '## Meaningful text and semantic code',
        '## Specify and test accessibility',
      ],
    },
  ],
  [
    'ux-content-design.md',
    {
      source: 'https://fluent2.microsoft.design/content-design/',
      sections: [
        '## Start with the audience',
        '## Write for comprehension and action',
        '## Capitalize and punctuate by platform',
        '## Organize and globalize content',
      ],
    },
  ],
  [
    'ux-design-tokens.md',
    {
      source: 'https://fluent2.microsoft.design/design-tokens/',
      sections: ['### Global tokens', '### Alias tokens', '## Apply theming'],
    },
  ],
  [
    'ux-handoffs.md',
    {
      source: 'https://fluent2.microsoft.design/handoffs/',
      sections: [
        '## Apply the three principles',
        '## Match certainty to user intent',
        '## Use AI responsibly',
        '## Select a visual pattern',
        '## Write handoff content',
      ],
    },
  ],
  [
    'ux-onboarding.md',
    {
      source: 'https://fluent2.microsoft.design/onboarding/',
      sections: [
        '## Apply the five principles',
        '## Choose one primary onboarding goal',
        '## Design the flow',
        '## Write onboarding content',
      ],
    },
  ],
  [
    'ux-wait.md',
    {
      source: 'https://fluent2.microsoft.design/wait-ux/',
      sections: [
        '## Apply the timing thresholds',
        '## Select a visual pattern',
        '## Handle behavior and fallback messaging',
        '## Make waiting accessible',
      ],
    },
  ],
]);
const AI_REFERENCES = new Map([
  [
    'working-with-ai.md',
    {
      category: 'workingWithAi',
      sources: [
        'https://fluent2.microsoft.design/responsible-AI/',
        'https://fluent2.microsoft.design/ai-harm/',
      ],
      sections: [
        '## Apply the five responsible AI principles',
        '## Handle agents and autonomy',
        '## Use transparent visual and content patterns',
        '## Anticipate AI harms',
        '## Collect feedback and harm reports',
        '## Evaluate responsible AI behavior',
        '## Implement in Flutter',
      ],
    },
  ],
  [
    'responsible-ai-rubric.md',
    {
      category: 'workingWithAi',
      sources: ['https://fluent2.microsoft.design/responsible-AI/'],
      sections: [
        '## Calculate the grade',
        '## Score transparency',
        '## Score expectations',
        '## Score overreliance protection',
        '## Score user control',
        '## Score feedback',
        '## Apply agent gates',
        '## Collect audit evidence',
      ],
    },
  ],
  [
    'content-engineering-prompts.md',
    {
      category: 'contentEngineering',
      sources: [
        'https://fluent2.microsoft.design/content-engineering/',
        'https://fluent2.microsoft.design/content-engineering/system-prompt-engineering/',
        'https://fluent2.microsoft.design/content-engineering/define-system-level-behavior/',
        'https://fluent2.microsoft.design/content-engineering/define-task-behavior-patterns/',
        'https://fluent2.microsoft.design/content-engineering/define-prompts-for-complex-tasks/',
        'https://fluent2.microsoft.design/content-engineering/design-interaction-behavior/',
        'https://fluent2.microsoft.design/content-engineering/define-tone-and-context-behavior/',
      ],
      sections: [
        '## Structure every system prompt',
        '## Define system-level behavior',
        '## Define task behavior patterns',
        '## Design complex tasks',
        '## Design interaction behavior',
        '## Define tone and context behavior',
        '## Connect behavior to Flutter UX',
      ],
    },
  ],
  [
    'content-engineering-evaluation.md',
    {
      category: 'contentEngineering',
      sources: [
        'https://fluent2.microsoft.design/content-engineering/evaluating-output-quality/',
        'https://fluent2.microsoft.design/content-engineering/define-good-output-quality/',
        'https://fluent2.microsoft.design/content-engineering/decide-what-to-evaluate-first/',
        'https://fluent2.microsoft.design/content-engineering/define-output-requirements-by-experience-type/',
        'https://fluent2.microsoft.design/content-engineering/build-a-prompt-set-and-assertions-for-an-eval/',
        'https://fluent2.microsoft.design/content-engineering/understand-eval-results/',
        'https://fluent2.microsoft.design/content-engineering/turn-eval-results-into-the-right-fixes/',
        'https://fluent2.microsoft.design/content-engineering/track-quality-over-time/',
      ],
      sections: [
        '## Check grounding before usefulness',
        '## Decide what to evaluate first',
        '## Define requirements by output type',
        '## Build prompt sets and assertions',
        '## Understand results',
        '## Apply the right fix',
        '## Track quality over time',
        '## Test the complete Flutter experience',
      ],
    },
  ],
]);

function fail(message) {
  process.stderr.write(`ERROR: ${message}\n`);
  process.exit(1);
}

async function walk(directory) {
  const entries = await readdir(directory, { withFileTypes: true });
  const files = [];
  for (const entry of entries) {
    const target = path.join(directory, entry.name);
    if (entry.isDirectory()) files.push(...(await walk(target)));
    if (entry.isFile()) files.push(target);
  }
  return files;
}

function parseFrontmatter(markdown) {
  const match = markdown.match(/^---\n([\s\S]*?)\n---\n/);
  if (!match) throw new Error('SKILL.md has no valid YAML frontmatter block.');
  const fields = new Map();
  for (const line of match[1].split('\n')) {
    const separator = line.indexOf(':');
    if (separator < 1) throw new Error(`Invalid frontmatter line: ${line}`);
    fields.set(line.slice(0, separator).trim(), line.slice(separator + 1).trim());
  }
  return fields;
}

try {
  const markdown = await readFile(SKILL_FILE, 'utf8');
  const fields = parseFrontmatter(markdown);
  const keys = [...fields.keys()];
  if (keys.length !== 2 || !fields.has('name') || !fields.has('description')) {
    throw new Error('Portable frontmatter must contain only name and description.');
  }
  if (fields.get('name') !== path.basename(SKILL_DIR)) {
    throw new Error('The skill name must match its parent directory.');
  }
  if (!/^[a-z0-9]+(?:-[a-z0-9]+)*$/.test(fields.get('name'))) {
    throw new Error('The skill name is not valid kebab-case.');
  }
  if (fields.get('name').length > 64) throw new Error('The skill name is too long.');
  if (fields.get('description').length > 1024) {
    throw new Error('The skill description is too long.');
  }

  const manifest = JSON.parse(
    await readFile(path.join(SKILL_DIR, 'references/source-manifest.json'), 'utf8'),
  );
  const designSources = new Set(manifest.categories?.designLanguage ?? []);
  if (designSources.size !== DESIGN_REFERENCES.size) {
    throw new Error(
      `Expected ${DESIGN_REFERENCES.size} design-language sources in the manifest, ` +
        `found ${designSources.size}.`,
    );
  }
  for (const [filename, { source, sections }] of DESIGN_REFERENCES) {
    const reference = await readFile(
      path.join(SKILL_DIR, 'references', filename),
      'utf8',
    );
    if (!reference.includes(source)) {
      throw new Error(`${filename} does not cite ${source}.`);
    }
    for (const section of sections) {
      if (!reference.includes(section)) {
        throw new Error(`${filename} is missing required section: ${section}.`);
      }
    }
    if (!markdown.includes(`references/${filename}`)) {
      throw new Error(`SKILL.md does not route readers to ${filename}.`);
    }
    if (!designSources.has(source)) {
      throw new Error(`The source manifest does not contain ${source}.`);
    }
  }
  const uxSources = new Set(manifest.categories?.uxFramework ?? []);
  if (uxSources.size !== UX_REFERENCES.size) {
    throw new Error(
      `Expected ${UX_REFERENCES.size} UX framework sources in the manifest, ` +
        `found ${uxSources.size}.`,
    );
  }
  for (const [filename, { source, sections }] of UX_REFERENCES) {
    const reference = await readFile(
      path.join(SKILL_DIR, 'references', filename),
      'utf8',
    );
    if (!reference.includes(source)) {
      throw new Error(`${filename} does not cite ${source}.`);
    }
    for (const section of sections) {
      if (!reference.includes(section)) {
        throw new Error(`${filename} is missing required section: ${section}.`);
      }
    }
    if (!markdown.includes(`references/${filename}`)) {
      throw new Error(`SKILL.md does not route readers to ${filename}.`);
    }
    if (!uxSources.has(source)) {
      throw new Error(`The source manifest does not contain ${source}.`);
    }
  }

  for (const [filename, { category, sources, sections }] of AI_REFERENCES) {
    const reference = await readFile(
      path.join(SKILL_DIR, 'references', filename),
      'utf8',
    );
    const manifestSources = new Set(manifest.categories?.[category] ?? []);
    for (const source of sources) {
      if (!reference.includes(source)) {
        throw new Error(`${filename} does not cite ${source}.`);
      }
      if (!manifestSources.has(source)) {
        throw new Error(`The ${category} manifest does not contain ${source}.`);
      }
    }
    for (const section of sections) {
      if (!reference.includes(section)) {
        throw new Error(`${filename} is missing required section: ${section}.`);
      }
    }
    if (!markdown.includes(`references/${filename}`)) {
      throw new Error(`SKILL.md does not route readers to ${filename}.`);
    }
  }

  const expectedWorkingWithAi = AI_REFERENCES.get('working-with-ai.md').sources;
  if (manifest.categories?.workingWithAi?.length !== expectedWorkingWithAi.length) {
    throw new Error(
      `Expected ${expectedWorkingWithAi.length} Working with AI sources, found ` +
        `${manifest.categories?.workingWithAi?.length ?? 0}.`,
    );
  }
  const expectedContentEngineering = [
    ...AI_REFERENCES.get('content-engineering-prompts.md').sources,
    ...AI_REFERENCES.get('content-engineering-evaluation.md').sources,
  ];
  if (
    new Set(manifest.categories?.contentEngineering ?? []).size !==
    expectedContentEngineering.length
  ) {
    throw new Error(
      `Expected ${expectedContentEngineering.length} Content Engineering ` +
        `sources, found ${manifest.categories?.contentEngineering?.length ?? 0}.`,
    );
  }

  const coverage = JSON.parse(
    await readFile(path.join(SKILL_DIR, 'references/widget-coverage.json'), 'utf8'),
  );
  if (coverage.schemaVersion !== 2) {
    throw new Error(`Expected widget coverage schema 2, found ${coverage.schemaVersion}.`);
  }
  const webCoreSources = manifest.categories?.webCore ?? [];
  if (webCoreSources.length !== 47 || coverage.officialWebCore?.length !== 47) {
    throw new Error(
      `Expected 47 component sources and mappings; found ${webCoreSources.length} ` +
        `sources and ${coverage.officialWebCore?.length ?? 0} mappings.`,
    );
  }
  const mappingsBySlug = new Map(
    coverage.officialWebCore.map((entry) => [entry.slug, entry]),
  );
  for (const source of webCoreSources) {
    const match = source.match(/\/core\/([^/]+)\/usage\/$/);
    if (!match) throw new Error(`Unexpected web-core source route: ${source}.`);
    const slug = match[1];
    const mapping = mappingsBySlug.get(slug);
    if (!mapping) throw new Error(`No Flutter mapping exists for ${source}.`);
    const reference = await readFile(
      path.join(SKILL_DIR, 'references', mapping.reference),
      'utf8',
    );
    if (!reference.includes(source)) {
      throw new Error(
        `${mapping.reference} is missing official ${slug} guidance source ${source}.`,
      );
    }
    if (!markdown.includes(`references/${mapping.reference}`)) {
      throw new Error(
        `SKILL.md does not route readers to ${mapping.reference} for ${slug}.`,
      );
    }
    const apiFilename = `api-${slug}.md`;
    const apiReference = await readFile(
      path.join(SKILL_DIR, 'references', apiFilename),
      'utf8',
    );
    if (!apiReference.includes(source)) {
      throw new Error(`${apiFilename} does not cite ${source}.`);
    }
    if (!apiReference.includes(`Status: **${mapping.status}**`)) {
      throw new Error(`${apiFilename} has stale mapping status.`);
    }
    for (const widget of mapping.widgets) {
      if (!apiReference.includes(`\`${widget}\``)) {
        throw new Error(`${apiFilename} is missing mapped widget ${widget}.`);
      }
    }
    for (const theme of mapping.themes ?? []) {
      if (!apiReference.includes(`\`${theme}\``)) {
        throw new Error(`${apiFilename} is missing mapped theme ${theme}.`);
      }
    }
    for (const widget of mapping.externalWidgets ?? []) {
      if (!apiReference.includes(`\`${widget}\``)) {
        throw new Error(`${apiFilename} is missing composed widget ${widget}.`);
      }
    }
    for (const type of mapping.relatedTypes ?? []) {
      if (!apiReference.includes(`\`${type}\``)) {
        throw new Error(`${apiFilename} is missing related type ${type}.`);
      }
    }
    if (!markdown.includes(`references/${apiFilename}`)) {
      throw new Error(`SKILL.md does not route readers to ${apiFilename}.`);
    }
  }

  const files = await walk(SKILL_DIR);
  const unresolvedMarker = new RegExp(`\\b${['TO', 'DO'].join('')}\\b`);
  for (const file of files) {
    if (!/\.(?:md|json|mjs|yaml)$/.test(file)) continue;
    const content = await readFile(file, 'utf8');
    if (unresolvedMarker.test(content)) {
      throw new Error(
        `Unresolved template marker in ${path.relative(SKILL_DIR, file)}.`,
      );
    }
    if (!file.endsWith('.md')) continue;
    for (const match of content.matchAll(/\]\(([^)]+)\)/g)) {
      const target = match[1];
      if (/^(?:https?:|#)/.test(target)) continue;
      const withoutFragment = target.split('#', 1)[0];
      await readFile(path.resolve(path.dirname(file), withoutFragment), 'utf8');
    }
  }

  const openaiYaml = await readFile(path.join(SKILL_DIR, 'agents/openai.yaml'), 'utf8');
  if (!openaiYaml.includes('Use $fluent-2-flutter')) {
    throw new Error('agents/openai.yaml default_prompt must mention $fluent-2-flutter.');
  }

  const audit = spawnSync(
    process.execPath,
    [path.join(SCRIPT_DIR, 'audit-widget-coverage.mjs')],
    { encoding: 'utf8' },
  );
  if (audit.status !== 0) {
    throw new Error(audit.stderr.trim() || audit.stdout.trim());
  }
  const apiAudit = spawnSync(
    process.execPath,
    [path.join(SCRIPT_DIR, 'generate-component-api.mjs')],
    { encoding: 'utf8' },
  );
  if (apiAudit.status !== 0) {
    throw new Error(apiAudit.stderr.trim() || apiAudit.stdout.trim());
  }
  process.stdout.write(audit.stdout);
  process.stdout.write(apiAudit.stdout);
  process.stdout.write(`Validated ${files.length} skill files.\n`);
} catch (error) {
  fail(error.message);
}
