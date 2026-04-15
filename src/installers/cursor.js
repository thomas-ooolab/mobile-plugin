import fs from 'fs-extra';
import { join } from 'path';
import Handlebars from 'handlebars';
import { loadSharedFiles, getTemplateDir } from '../utils.js';
import { writeWithBackup } from './common.js';

export async function syncCursor(projectDir, opts = {}) {
  const rules = await loadSharedFiles('rules');
  const skills = await loadSharedFiles('skills');
  const agents = await loadSharedFiles('agents');

  // Build .cursorrules from template
  const templatePath = join(getTemplateDir(), '.cursorrules.hbs');
  const templateContent = await fs.readFile(templatePath, 'utf-8');
  const template = Handlebars.compile(templateContent);

  const cursorrules = template({
    rules,
    skills,
    agents,
    generatedAt: new Date().toISOString(),
  });

  await writeWithBackup(join(projectDir, '.cursorrules'), cursorrules, opts);

  // Install individual rule files in .cursor/rules/
  const cursorRulesDir = join(projectDir, '.cursor', 'rules');
  await fs.ensureDir(cursorRulesDir);

  for (const rule of rules) {
    await writeWithBackup(
      join(cursorRulesDir, `${rule.name}.mdc`),
      buildCursorRule(rule),
      opts
    );
  }

  // Install agents as .cursor/rules/ with agent prefix
  for (const agent of agents) {
    await writeWithBackup(
      join(cursorRulesDir, `agent-${agent.name}.mdc`),
      buildCursorRule(agent),
      opts
    );
  }
}

function buildCursorRule(item) {
  const parts = [];
  parts.push('---');
  if (item.frontmatter.description) {
    parts.push(`description: ${item.frontmatter.description}`);
  }
  if (item.frontmatter.globs) {
    parts.push(`globs: ${item.frontmatter.globs}`);
  }
  if (item.frontmatter.alwaysApply) {
    parts.push(`alwaysApply: ${item.frontmatter.alwaysApply}`);
  } else {
    parts.push('alwaysApply: true');
  }
  parts.push('---');
  parts.push('');
  parts.push(item.body);
  return parts.join('\n');
}
