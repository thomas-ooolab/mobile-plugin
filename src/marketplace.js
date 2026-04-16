import fs from 'fs-extra';
import { join } from 'path';
import { getRootDir } from './utils.js';

/**
 * Reads marketplace name and GitHub repo from .claude-plugin/marketplace.json
 * and package.json so installers stay in sync with a single source of truth.
 */
export async function getMarketplaceConfig() {
  const rootDir = getRootDir();

  const marketplace = await fs.readJson(
    join(rootDir, '.claude-plugin', 'marketplace.json')
  );

  const pkg = await fs.readJson(join(rootDir, 'package.json'));
  const repoUrl = pkg.repository?.url || '';
  // git+https://github.com/org/repo.git → org/repo
  const githubRepo = repoUrl.replace(/^git\+https:\/\/github\.com\//, '').replace(/\.git$/, '');

  return {
    marketplaceName: marketplace.name,
    githubRepo,
  };
}
