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
