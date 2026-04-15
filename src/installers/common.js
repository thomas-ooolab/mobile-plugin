import fs from 'fs-extra';
import { join } from 'path';
import chalk from 'chalk';

const CONFIG_FILE = '.ai-plugin.json';

export async function initProject(projectDir, target) {
  const configPath = join(projectDir, CONFIG_FILE);
  let config = { targets: [], version: '0.1.0' };

  if (await fs.pathExists(configPath)) {
    config = await fs.readJson(configPath);
  }

  if (!config.targets.includes(target)) {
    config.targets.push(target);
  }

  await fs.writeJson(configPath, config, { spaces: 2 });
}

export async function getConfig(projectDir) {
  const configPath = join(projectDir, CONFIG_FILE);
  if (await fs.pathExists(configPath)) {
    return fs.readJson(configPath);
  }
  return null;
}

export async function writeWithBackup(filePath, content, opts = {}) {
  if (opts.dryRun) {
    console.log(chalk.yellow(`[dry-run] Would write: ${filePath}`));
    return;
  }

  if (await fs.pathExists(filePath)) {
    const existing = await fs.readFile(filePath, 'utf-8');
    if (existing === content) {
      console.log(chalk.dim(`  unchanged: ${filePath}`));
      return;
    }
  }

  await fs.ensureDir(join(filePath, '..'));
  await fs.writeFile(filePath, content, 'utf-8');
  console.log(chalk.green(`  wrote: ${filePath}`));
}
