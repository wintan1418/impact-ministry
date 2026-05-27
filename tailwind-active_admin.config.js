import { execSync } from 'child_process';
import { existsSync } from 'fs';
import { join } from 'path';

// Resolve the activeadmin gem path via bundler. Last line guards against DEBUG lines.
const activeAdminPath = execSync('bundle show activeadmin', { encoding: 'utf-8' })
  .trim()
  .split(/\r?\n/)
  .pop();

// Import the plugin directly from the gem (avoids needing @activeadmin/activeadmin
// in node_modules — we don't use a JS bundler).
const pluginPath = join(activeAdminPath, 'plugin.js');
const activeAdminPlugin = existsSync(pluginPath)
  ? (await import(pluginPath)).default
  : null;

export default {
  content: [
    `${activeAdminPath}/vendor/javascript/flowbite.js`,
    `${activeAdminPath}/plugin.js`,
    `${activeAdminPath}/app/views/**/*.{arb,erb,html,rb}`,
    './app/admin/**/*.{arb,erb,html,rb}',
    './app/views/active_admin/**/*.{arb,erb,html,rb}',
    './app/views/admin/**/*.{arb,erb,html,rb}',
    './app/views/layouts/active_admin*.{erb,html}',
    './app/javascript/**/*.js'
  ],
  darkMode: 'selector',
  plugins: activeAdminPlugin ? [activeAdminPlugin] : [],
};
