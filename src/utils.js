import { readdir, readFile } from 'fs/promises';
import { join, dirname, basename, extname } from 'path';
import { fileURLToPath } from 'url';
import chalk from 'chalk';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SHARED_DIR = join(__dirname, '..', 'shared');

const CATEGORIES = ['rules', 'skills', 'agents', 'commands'];

export async function listShared(category) {
  const categories = category ? [category] : CATEGORIES;

  for (const cat of categories) {
    const dir = join(SHARED_DIR, cat);
    let files;
    try {
      files = await readdir(dir);
    } catch {
      continue;
    }

    const mdFiles = files.filter(f => extname(f) === '.md');
    if (mdFiles.length === 0) continue;

    console.log(chalk.bold(`\n${cat.toUpperCase()}`));
    for (const file of mdFiles) {
      const content = await readFile(join(dir, file), 'utf-8');
      const title = extractTitle(content) || basename(file, '.md');
      const desc = extractDescription(content);
      console.log(`  ${chalk.cyan(basename(file, '.md'))} — ${desc || title}`);
    }
  }
}

export async function loadSharedFiles(category) {
  const dir = join(SHARED_DIR, category);
  let files;
  try {
    files = await readdir(dir);
  } catch {
    return [];
  }

  const results = [];
  for (const file of files.filter(f => extname(f) === '.md')) {
    const content = await readFile(join(dir, file), 'utf-8');
    const { frontmatter, body } = parseFrontmatter(content);
    results.push({
      name: basename(file, '.md'),
      filename: file,
      frontmatter,
      body,
      raw: content,
    });
  }
  return results;
}

export function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  if (!match) return { frontmatter: {}, body: content };

  const frontmatter = {};
  for (const line of match[1].split('\n')) {
    const idx = line.indexOf(':');
    if (idx > 0) {
      const key = line.slice(0, idx).trim();
      const val = line.slice(idx + 1).trim();
      frontmatter[key] = val;
    }
  }
  return { frontmatter, body: match[2].trim() };
}

function extractTitle(content) {
  const match = content.match(/^#\s+(.+)$/m);
  return match ? match[1] : null;
}

function extractDescription(content) {
  const { frontmatter } = parseFrontmatter(content);
  return frontmatter.description || null;
}

export function getSharedDir() {
  return SHARED_DIR;
}

export function getTemplateDir() {
  return join(__dirname, '..', 'templates');
}
