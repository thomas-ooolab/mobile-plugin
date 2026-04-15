import fs from 'fs-extra';
import { join } from 'path';
import Handlebars from 'handlebars';
import { loadSharedFiles, getTemplateDir } from '../utils.js';
import { writeWithBackup } from './common.js';

export async function syncCursor(projectDir, opts = {}) {
  const rules = await loadSharedFiles('rules');
  const skills = await loadSharedFiles('skills');
  const agents = await loadSharedFiles('agents');
  const commands = await loadSharedFiles('commands');

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

  // Install skills as .cursor/skills/ files
  const cursorSkillsDir = join(projectDir, '.cursor', 'skills');
  await fs.ensureDir(cursorSkillsDir);

  for (const skill of skills) {
    await writeWithBackup(
      join(cursorSkillsDir, `${skill.name}`, 'SKILL.md'),
      skill.raw,
      opts
    );
    // Write extra files (reference.md, etc.)
    for (const [extraName, extraContent] of Object.entries(skill.extraFiles || {})) {
      await writeWithBackup(
        join(cursorSkillsDir, `${skill.name}`, `${extraName}.md`),
        extraContent,
        opts
      );
    }
  }

  // Install agents as .cursor/agents/ files
  const cursorAgentsDir = join(projectDir, '.cursor', 'agents');
  await fs.ensureDir(cursorAgentsDir);

  for (const agent of agents) {
    await writeWithBackup(
      join(cursorAgentsDir, `${agent.name}.md`),
      agent.raw,
      opts
    );
  }

  // Install commands as .cursor/commands/ files
  const cursorCommandsDir = join(projectDir, '.cursor', 'commands');
  await fs.ensureDir(cursorCommandsDir);

  for (const cmd of commands) {
    await writeWithBackup(
      join(cursorCommandsDir, `${cmd.name}.md`),
      cmd.raw,
      opts
    );
  }

  // Copy command scripts
  await copyScripts(projectDir, opts);
}

async function copyScripts(projectDir, opts) {
  const { getSharedDir } = await import('../utils.js');
  const scriptsDir = join(getSharedDir(), 'commands', 'scripts');
  const targetDir = join(projectDir, '.cursor', 'commands', 'scripts');

  if (!await fs.pathExists(scriptsDir)) return;

  const files = await fs.readdir(scriptsDir);
  if (files.length === 0) return;

  await fs.ensureDir(targetDir);
  for (const file of files) {
    const src = join(scriptsDir, file);
    const dest = join(targetDir, file);
    if (opts.dryRun) {
      console.log(`  [dry-run] Would copy: ${dest}`);
      continue;
    }
    await fs.copy(src, dest);
    await fs.chmod(dest, 0o755);
    console.log(`  copied: ${dest}`);
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
