import { readdir, readFile, stat } from 'fs/promises';
import { join, dirname, basename, extname } from 'path';
import { fileURLToPath } from 'url';
import chalk from 'chalk';

const __dirname = dirname(fileURLToPath(import.meta.url));
const ROOT_DIR = join(__dirname, '..');

const CATEGORIES = ['rules', 'skills', 'agents', 'commands'];
const STACKS = ['mobile', 'be', 'fe'];

export function getStackDir(stack = 'mobile') {
  return join(ROOT_DIR, 'plugins', stack);
}

export function getRootDir() {
  return ROOT_DIR;
}

export async function listShared(category, stack = 'mobile') {
  const categories = category ? [category] : CATEGORIES;

  for (const cat of categories) {
    const items = await loadSharedFiles(cat, stack);
    if (items.length === 0) continue;

    console.log(chalk.bold(`\n${cat.toUpperCase()}`));
    for (const item of items) {
      const desc = item.frontmatter.description || extractTitle(item.raw) || item.name;
      console.log(`  ${chalk.cyan(item.name)} — ${desc}`);
    }
  }
}

export async function listAllStacks(category) {
  for (const stack of STACKS) {
    const dir = getStackDir(stack);
    try {
      await stat(dir);
    } catch {
      continue;
    }
    console.log(chalk.bold.blue(`\n[${stack}]`));
    await listShared(category, stack);
  }
}

export async function loadSharedFiles(category, stack = 'mobile') {
  const dir = join(getStackDir(stack), category);
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

        // Collect extra files (reference dirs, etc.)
        const extraFiles = {};
        const subEntries = await readdir(entryPath);
        for (const sf of subEntries) {
          const sfPath = join(entryPath, sf);
          const sfStat = await stat(sfPath);
          if (sfStat.isDirectory()) {
            // Recurse one level for reference/ subdirs
            const subFiles = await readdir(sfPath);
            for (const subFile of subFiles) {
              if (extname(subFile) === '.md') {
                extraFiles[`${sf}-${basename(subFile, '.md')}`] = await readFile(join(sfPath, subFile), 'utf-8');
              }
            }
          } else if (sf !== 'SKILL.md' && extname(sf) === '.md') {
            extraFiles[basename(sf, '.md')] = await readFile(sfPath, 'utf-8');
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

export { STACKS };
