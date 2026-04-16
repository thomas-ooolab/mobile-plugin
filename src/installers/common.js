import fs from 'fs-extra';
import { join } from 'path';

const CONFIG_FILE = '.ai-plugin.json';

export async function initProject(projectDir, target, stack = 'mobile') {
  const configPath = join(projectDir, CONFIG_FILE);
  let config = { targets: [], stack, version: '0.1.0' };

  if (await fs.pathExists(configPath)) {
    config = await fs.readJson(configPath);
  }

  if (!config.targets.includes(target)) {
    config.targets.push(target);
  }
  config.stack = stack;

  await fs.writeJson(configPath, config, { spaces: 2 });
}

export async function getConfig(projectDir) {
  const configPath = join(projectDir, CONFIG_FILE);
  if (await fs.pathExists(configPath)) {
    return fs.readJson(configPath);
  }
  return null;
}

