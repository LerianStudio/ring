/**
 * Ring Dev Team plugin for OpenCode.ai
 *
 * Registers the ring-dev-team skills directory with OpenCode. The `using-ring`
 * bootstrap injection is owned by the ring-default plugin — install both plugins
 * together for full functionality.
 */

import path from 'path';
import { fileURLToPath } from 'url';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

export const RingDevTeamPlugin = async ({ client, directory }) => {
  const ringSkillsDir = path.resolve(__dirname, '../../skills');

  return {
    // Register the ring-dev-team skills path so OpenCode discovers them without
    // requiring manual symlinks or config file edits.
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(ringSkillsDir)) {
        config.skills.paths.push(ringSkillsDir);
      }
    }
  };
};
