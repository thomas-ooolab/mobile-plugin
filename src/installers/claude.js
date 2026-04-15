import fs from 'fs-extra';
import { join } from 'path';
import Handlebars from 'handlebars';
import { loadSharedFiles, getTemplateDir } from '../utils.js';
import { writeWithBackup } from './common.js';

export async function syncClaude(projectDir, opts = {}) {
  const rules = await loadSharedFiles('rules');
  const skills = await loadSharedFiles('skills');
  const agents = await loadSharedFiles('agents');
  const commands = await loadSharedFiles('commands');

  // Build CLAUDE.md from template
  const templatePath = join(getTemplateDir(), 'CLAUDE.md.hbs');
  const templateContent = await fs.readFile(templatePath, 'utf-8');
  const template = Handlebars.compile(templateContent);

  const claudeMd = template({
    rules,
    skills,
    agents,
    commands,
    generatedAt: new Date().toISOString(),
  });

  await writeWithBackup(join(projectDir, 'CLAUDE.md'), claudeMd, opts);

  // Install skills as .claude/skills/ files
  const claudeSkillsDir = join(projectDir, '.claude', 'skills');
  await fs.ensureDir(claudeSkillsDir);

  for (const skill of skills) {
    const skillContent = buildClaudeSkill(skill);
    await writeWithBackup(
      join(claudeSkillsDir, `${skill.name}.md`),
      skillContent,
      opts
    );
    // Write extra files (reference.md, etc.) alongside the skill
    for (const [extraName, extraContent] of Object.entries(skill.extraFiles || {})) {
      await writeWithBackup(
        join(claudeSkillsDir, `${skill.name}-${extraName}.md`),
        extraContent,
        opts
      );
    }
  }

  // Install commands as .claude/commands/ files
  const claudeCommandsDir = join(projectDir, '.claude', 'commands');
  await fs.ensureDir(claudeCommandsDir);

  for (const cmd of commands) {
    await writeWithBackup(
      join(claudeCommandsDir, `${cmd.name}.md`),
      cmd.raw,
      opts
    );
  }

  // Copy command scripts if they exist
  await copyScripts(projectDir, opts);
}

async function copyScripts(projectDir, opts) {
  const { getSharedDir } = await import('../utils.js');
  const scriptsDir = join(getSharedDir(), 'commands', 'scripts');
  const targetDir = join(projectDir, '.claude', 'commands', 'scripts');

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

function buildClaudeSkill(skill) {
  const parts = [];
  if (skill.frontmatter.description) {
    parts.push(`# ${skill.name}\n`);
    parts.push(`${skill.frontmatter.description}\n`);
  }
  parts.push(skill.body);
  return parts.join('\n');
}
