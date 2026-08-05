#!/usr/bin/env node

import { readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { fileURLToPath } from 'node:url';

const SITEMAP_INDEX = 'https://fluent2.microsoft.design/sitemap-index.xml';
const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const OUTPUT = path.resolve(SCRIPT_DIR, '../references/source-manifest.json');
const args = new Set(process.argv.slice(2));
const allowedArgs = new Set(['--write', '--check', '--verify-links']);

for (const arg of args) {
  if (!allowedArgs.has(arg)) {
    fail(`Unknown argument: ${arg}`);
  }
}

const foundationPaths = new Set([
  '/',
  '/accessibility/',
  '/color/',
  '/content-design/',
  '/design-principles/',
  '/design-tokens/',
  '/elevation/',
  '/get-started/design/',
  '/get-started/develop/',
  '/get-started/whatisnew/',
  '/iconography/',
  '/layout/',
  '/material/',
  '/motion/',
  '/shapes/',
  '/typography/',
]);

const supplementalPaths = new Set([
  '/color-tokens/',
  '/color-tokens2/',
  '/component-roadmap/',
  '/components/react-native/',
  '/get-started/contribute/',
]);

const designLanguagePaths = new Set([
  '/color/',
  '/elevation/',
  '/iconography/',
  '/layout/',
  '/material/',
  '/motion/',
  '/shapes/',
  '/typography/',
]);

const uxFrameworkPaths = new Set([
  '/accessibility/',
  '/content-design/',
  '/design-tokens/',
  '/handoffs/',
  '/onboarding/',
  '/wait-ux/',
]);

const workingWithAiPaths = new Set([
  '/responsible-AI/',
  '/ai-harm/',
]);

const contentEngineeringPaths = new Set([
  '/content-engineering/',
  '/content-engineering/system-prompt-engineering/',
  '/content-engineering/define-system-level-behavior/',
  '/content-engineering/define-task-behavior-patterns/',
  '/content-engineering/define-prompts-for-complex-tasks/',
  '/content-engineering/design-interaction-behavior/',
  '/content-engineering/define-tone-and-context-behavior/',
  '/content-engineering/evaluating-output-quality/',
  '/content-engineering/define-good-output-quality/',
  '/content-engineering/decide-what-to-evaluate-first/',
  '/content-engineering/define-output-requirements-by-experience-type/',
  '/content-engineering/build-a-prompt-set-and-assertions-for-an-eval/',
  '/content-engineering/understand-eval-results/',
  '/content-engineering/turn-eval-results-into-the-right-fixes/',
  '/content-engineering/track-quality-over-time/',
]);

function fail(message) {
  process.stderr.write(`ERROR: ${message}\n`);
  process.exit(1);
}

async function fetchText(url) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 30_000);
  try {
    const response = await fetch(url, {
      headers: { 'user-agent': 'fluent-2-flutter-skill-crawler/1.0' },
      signal: controller.signal,
    });
    if (!response.ok) {
      throw new Error(`${response.status} ${response.statusText}`);
    }
    return await response.text();
  } catch (error) {
    throw new Error(`Could not fetch ${url}: ${error.message}`);
  } finally {
    clearTimeout(timer);
  }
}

function extractLocations(xml) {
  return [...xml.matchAll(/<loc>([^<]+)<\/loc>/g)].map((match) =>
    match[1].trim(),
  );
}

function sorted(values) {
  return [...new Set(values)].sort();
}

function categorize(urls) {
  const categories = {
    foundations: [],
    designLanguage: [],
    uxFramework: [],
    workingWithAi: [],
    contentEngineering: [],
    supplemental: [],
    platformOverviews: [],
    webCore: [],
    webAi: [],
    ios: [],
    android: [],
  };

  for (const url of urls) {
    const pathname = new URL(url).pathname;
    if (foundationPaths.has(pathname)) categories.foundations.push(url);
    if (designLanguagePaths.has(pathname)) categories.designLanguage.push(url);
    if (uxFrameworkPaths.has(pathname)) categories.uxFramework.push(url);
    if (workingWithAiPaths.has(pathname)) categories.workingWithAi.push(url);
    if (contentEngineeringPaths.has(pathname)) {
      categories.contentEngineering.push(url);
    }
    if (supplementalPaths.has(pathname)) categories.supplemental.push(url);
    if (
      /^\/components\/(web\/react|ios|android|windows)\/$/.test(pathname)
    ) {
      categories.platformOverviews.push(url);
    }
    if (/^\/components\/web\/react\/core\/[^/]+\/usage\/$/.test(pathname)) {
      categories.webCore.push(url);
    }
    if (/^\/components\/web\/react\/ai\/.+\/usage\/$/.test(pathname)) {
      categories.webAi.push(url);
    }
    if (/^\/components\/ios\/core\/[^/]+\/usage\/$/.test(pathname)) {
      categories.ios.push(url);
    }
    if (/^\/components\/android\/core\/[^/]+\/usage\/$/.test(pathname)) {
      categories.android.push(url);
    }
  }

  for (const key of Object.keys(categories)) {
    categories[key] = sorted(categories[key]);
  }
  return categories;
}

async function crawl() {
  const indexXml = await fetchText(SITEMAP_INDEX);
  const sitemapUrls = extractLocations(indexXml);
  if (sitemapUrls.length === 0) {
    throw new Error('The sitemap index did not contain any sitemap locations.');
  }

  const sitemapXml = await Promise.all(sitemapUrls.map(fetchText));
  const allUrls = sorted(sitemapXml.flatMap(extractLocations));
  const categories = categorize(allUrls);

  return {
    schemaVersion: 1,
    crawledAt: new Date().toISOString(),
    source: SITEMAP_INDEX,
    sitemapUrls,
    counts: Object.fromEntries(
      Object.entries(categories).map(([key, values]) => [key, values.length]),
    ),
    categories,
  };
}

function comparable(manifest) {
  return JSON.stringify(
    {
      schemaVersion: manifest.schemaVersion,
      source: manifest.source,
      sitemapUrls: manifest.sitemapUrls,
      counts: manifest.counts,
      categories: manifest.categories,
    },
    null,
    2,
  );
}

async function verifyLinks(urls) {
  const queue = [...urls];
  const failures = [];
  const workers = Array.from({ length: Math.min(8, queue.length) }, async () => {
    while (queue.length > 0) {
      const url = queue.shift();
      try {
        const controller = new AbortController();
        const timer = setTimeout(() => controller.abort(), 30_000);
        const response = await fetch(url, {
          headers: { 'user-agent': 'fluent-2-flutter-skill-crawler/1.0' },
          signal: controller.signal,
        });
        clearTimeout(timer);
        if (!response.ok) failures.push(`${url}: HTTP ${response.status}`);
        await response.body?.cancel();
      } catch (error) {
        failures.push(`${url}: ${error.message}`);
      }
    }
  });
  await Promise.all(workers);
  if (failures.length > 0) {
    throw new Error(`Source verification failed:\n${failures.join('\n')}`);
  }
}

try {
  const manifest = await crawl();
  if (manifest.counts.webCore !== 47) {
    throw new Error(
      `Expected 47 web-core component pages, found ${manifest.counts.webCore}. ` +
        'Review the upstream route change before accepting it.',
    );
  }
  if (manifest.counts.designLanguage !== designLanguagePaths.size) {
    throw new Error(
      `Expected ${designLanguagePaths.size} design-language pages, found ` +
        `${manifest.counts.designLanguage}. Review the upstream route change ` +
        'before accepting it.',
    );
  }
  if (manifest.counts.uxFramework !== uxFrameworkPaths.size) {
    throw new Error(
      `Expected ${uxFrameworkPaths.size} UX framework pages, found ` +
        `${manifest.counts.uxFramework}. Review the upstream route change ` +
        'before accepting it.',
    );
  }
  if (manifest.counts.workingWithAi !== workingWithAiPaths.size) {
    throw new Error(
      `Expected ${workingWithAiPaths.size} Working with AI pages, found ` +
        `${manifest.counts.workingWithAi}. Review the upstream route change ` +
        'before accepting it.',
    );
  }
  if (manifest.counts.contentEngineering !== contentEngineeringPaths.size) {
    throw new Error(
      `Expected ${contentEngineeringPaths.size} Content Engineering pages, found ` +
        `${manifest.counts.contentEngineering}. Review the upstream route ` +
        'change before accepting it.',
    );
  }

  if (args.has('--verify-links')) {
    await verifyLinks(Object.values(manifest.categories).flat());
  }

  if (args.has('--check')) {
    const existing = JSON.parse(await readFile(OUTPUT, 'utf8'));
    if (comparable(existing) !== comparable(manifest)) {
      throw new Error(
        'The committed source manifest differs from the live Fluent 2 sitemap. ' +
          'Run with --write and review the diff.',
      );
    }
  }

  if (args.has('--write')) {
    await writeFile(OUTPUT, `${JSON.stringify(manifest, null, 2)}\n`);
    process.stdout.write(`Wrote ${OUTPUT}\n`);
  }

  process.stdout.write(
    `${Object.entries(manifest.counts)
      .map(([key, value]) => `${key}=${value}`)
      .join(' ')}\n`,
  );
} catch (error) {
  fail(error.message);
}
