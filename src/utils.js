import { readdir, readFile, stat } from 'fs/promises';
import { join, dirname, basename, extname } from 'path';
import { fileURLToPath } from 'url';
import chalk from 'chalk';

const __dirname = dirname(fileURLToPath(import.meta.url));
const SHARED_DIR = join(__dirname, '..', 'shared');

const CATEGORIES = ['rules', 'skills', 'agents', 'commands'];

export async function listShared(category) {
  const categories = category ? [category] : CATEGORIES;

  for (const cat of categories) {
    const items = await loadSharedFiles(cat);
    if (items.length === 0) continue;

    console.log(chalk.bold(`\n${cat.toUpperCase()}`));
    for (const item of items) {
      const desc = item.frontmatter.description || extractTitle(item.raw) || item.name;
      console.log(`  ${chalk.cyan(item.name)} — ${desc}`);
    }
  }
}

export async function loadSharedFiles(category) {
  const dir = join(SHARED_DIR, category);
  let entries;
  try {
    entries = await readdir(dir);
  } catch {
    return [];
  }

  const results = [];

  for (const entry of entries) {
    const entryPath = join(dir, entry);
    const entryStat = await stat(entryPath);

    if (entryStat.isDirectory()) {
      // Subdir: look for SKILL.md as primary file
      const skillPath = join(entryPath, 'SKILL.md');
      try {
        const content = await readFile(skillPath, 'utf-8');
        const { frontmatter, body } = parseFrontmatter(content);

        // Collect extra files (reference.md, etc.)
        const extraFiles = {};
        const subFiles = await readdir(entryPath);
        for (const sf of subFiles) {
          if (sf !== 'SKILL.md' && extname(sf) === '.md') {
            extraFiles[basename(sf, '.md')] = await readFile(join(entryPath, sf), 'utf-8');
          }
        }

        results.push({
          name: entry,
          filename: 'SKILL.md',
          dir: entryPath,
          frontmatter,
          body,
          raw: content,
          extraFiles,
        });
      } catch {
        // No SKILL.md in subdir, skip
      }
    } else if (extname(entry) === '.md') {
      // Flat .md file (rules, agents, commands)
      const content = await readFile(entryPath, 'utf-8');
      const { frontmatter, body } = parseFrontmatter(content);
      results.push({
        name: basename(entry, '.md'),
        filename: entry,
        frontmatter,
        body,
        raw: content,
        extraFiles: {},
      });
    }
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
