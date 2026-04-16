import { program } from 'commander';
import chalk from 'chalk';
import { initProject } from './installers/common.js';
import { syncClaude } from './installers/claude.js';
import { syncCursor } from './installers/cursor.js';
import { listShared, listAllStacks } from './utils.js';

const TARGETS = {
  claude: syncClaude,
  cursor: syncCursor,
};

export function cli(argv) {
  program
    .name('ooolab-plugin')
    .description('Shared AI skills, agents, rules, and commands')
    .version('0.1.0');

  program
    .command('init')
    .description('Initialize AI plugin in current project')
    .option('-t, --target <tools...>', 'AI tools to configure (claude, cursor)', ['claude', 'cursor'])
    .option('-s, --stack <name>', 'Tech stack to install (mobile, be, fe)', 'mobile')
    .option('--dry-run', 'Show what would change without writing')
    .action(async (opts) => {
      const projectDir = process.cwd();
      console.log(chalk.blue(`Initializing AI plugin (stack: ${opts.stack})...`));

      for (const target of opts.target) {
        if (!TARGETS[target]) {
          console.log(chalk.red(`Unknown target: ${target}`));
          continue;
        }
        await initProject(projectDir, target, opts.stack);
        await TARGETS[target](projectDir, { stack: opts.stack, dryRun: opts.dryRun });
        console.log(chalk.green(`✓ ${target} configured`));
      }

      console.log(chalk.green('\nDone! AI configs installed.'));
    });

  program
    .command('sync')
    .description('Sync latest shared rules/skills to project')
    .option('-t, --target <tools...>', 'AI tools to sync (claude, cursor)')
    .option('-s, --stack <name>', 'Tech stack to sync (mobile, be, fe)')
    .option('--dry-run', 'Show what would change without writing')
    .action(async (opts) => {
      const projectDir = process.cwd();
      const targets = opts.target || (await detectTargets(projectDir));

      if (targets.length === 0) {
        console.log(chalk.yellow('No AI tools detected. Run `ooolab-plugin init` first.'));
        return;
      }

      const stack = opts.stack || (await detectStack(projectDir)) || 'mobile';

      for (const target of targets) {
        if (!TARGETS[target]) {
          console.log(chalk.red(`Unknown target: ${target}`));
          continue;
        }
        console.log(chalk.blue(`Syncing ${target} (stack: ${stack})...`));
        await TARGETS[target](projectDir, { stack, dryRun: opts.dryRun });
        console.log(chalk.green(`✓ ${target} synced`));
      }
    });

  program
    .command('list')
    .description('List available shared rules, skills, agents, commands')
    .option('-c, --category <type>', 'Filter by category (rules, skills, agents, commands)')
    .option('-s, --stack <name>', 'Stack to list (mobile, be, fe) — omit for all stacks')
    .action(async (opts) => {
      if (opts.stack) {
        await listShared(opts.category, opts.stack);
      } else {
        await listAllStacks(opts.category);
      }
    });

  program.parse(argv);
}

async function detectTargets(projectDir) {
  const targets = [];
  const { existsSync } = await import('fs');

  if (existsSync(`${projectDir}/CLAUDE.md`) || existsSync(`${projectDir}/.claude`)) {
    targets.push('claude');
  }
  if (existsSync(`${projectDir}/.cursorrules`) || existsSync(`${projectDir}/.cursor`)) {
    targets.push('cursor');
  }
  return targets;
}

async function detectStack(projectDir) {
  const { existsSync } = await import('fs');
  const configPath = `${projectDir}/.ooolab-plugin.json`;
  if (existsSync(configPath)) {
    const fs = await import('fs-extra');
    const config = await fs.default.readJson(configPath);
    return config.stack || null;
  }
  return null;
}
