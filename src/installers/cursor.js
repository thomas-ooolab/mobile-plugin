import fs from 'fs-extra';
import { join } from 'path';
import chalk from 'chalk';
import { getMarketplaceConfig } from '../marketplace.js';

export async function syncCursor(projectDir, opts = {}) {
  const stack = opts.stack || 'mobile';
  const { marketplaceName, githubRepo } = await getMarketplaceConfig();
  const settingsPath = join(projectDir, '.cursor', 'settings.json');

  let settings = {};
  if (await fs.pathExists(settingsPath)) {
    settings = await fs.readJson(settingsPath);
  }

  // Register marketplace
  settings.extraKnownMarketplaces = settings.extraKnownMarketplaces || {};
  settings.extraKnownMarketplaces[marketplaceName] = {
    ...settings.extraKnownMarketplaces[marketplaceName],
    source: {
      source: 'github',
      repo: githubRepo,
    },
  };

  // Enable plugin for this stack
  settings.enabledPlugins = settings.enabledPlugins || {};
  settings.enabledPlugins[`${stack}@${marketplaceName}`] = true;

  // Register plugin entry
  settings.plugins = settings.plugins || {};
  settings.plugins[`${marketplaceName}/${stack}`] = {
    ...settings.plugins[`${marketplaceName}/${stack}`],
    enabled: true,
    gitUrl: `https://github.com/${githubRepo}`,
    gitRef: opts.gitRef || 'main',
  };

  await fs.ensureDir(join(projectDir, '.cursor'));

  if (opts.dryRun) {
    console.log(chalk.yellow(`  [dry-run] Would write: ${settingsPath}`));
    console.log(chalk.yellow(`  [dry-run] marketplace: ${marketplaceName} → ${githubRepo}`));
    console.log(chalk.yellow(`  [dry-run] enabledPlugins: ${stack}@${marketplaceName}`));
    console.log(chalk.yellow(`  [dry-run] plugins: ${marketplaceName}/${stack}`));
    return;
  }

  await fs.writeJson(settingsPath, settings, { spaces: 2 });
  console.log(chalk.green(`  registered marketplace: ${marketplaceName} (${githubRepo})`));
  console.log(chalk.green(`  enabled plugin: ${stack}@${marketplaceName}`));
  console.log(chalk.green(`  registered plugin entry: ${marketplaceName}/${stack}`));
}
