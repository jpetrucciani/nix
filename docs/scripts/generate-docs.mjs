import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const docsRoot = path.resolve(scriptDir, '..');
const repoRoot = path.resolve(docsRoot, '..');
const referenceRoot = path.join(docsRoot, 'reference');

const repoBlobBaseUrl = process.env.DOCS_REPO_BLOB_URL || 'https://github.com/jpetrucciani/nix/blob/main';
const repoTreeBaseUrl = process.env.DOCS_REPO_TREE_URL || 'https://github.com/jpetrucciani/nix/tree/main';

const generatedEntryDirs = ['hosts', 'modules', 'packages', 'wrappers', 'scripts', 'workflows'];
const excludedScripts = new Set(['foo']);

const sections = {
  hosts: {
    file: 'reference/generated-hosts.md',
    title: 'Generated Host Index',
    description: 'Host directories under `hosts/` with a `configuration.nix` file are listed here.',
    guide: { text: 'Hosts', link: '/hosts/index' },
  },
  modules: {
    file: 'reference/generated-modules.md',
    title: 'Generated Module Index',
    description: 'Nix modules discovered under `hosts/modules/` are listed here.',
    guide: { text: 'Modules', link: '/modules/index' },
  },
  packages: {
    file: 'reference/generated-packages.md',
    title: 'Generated Package Index',
    description: 'Nix package definitions discovered under `pkgs/` are listed here.',
    guide: { text: 'Packages', link: '/packages/index' },
  },
  wrappers: {
    file: 'reference/generated-wrappers.md',
    title: 'Generated Wrapper Index',
    description: 'Wrapper-related files from `mods/hms.nix`, `mods/hax.nix`, and `mods/pog/*.nix` are listed here.',
    guide: { text: 'Tooling', link: '/tooling/index' },
  },
  scripts: {
    file: 'reference/generated-scripts.md',
    title: 'Generated Script Index',
    description: 'Script outputs parsed from `scripts.nix` are listed here.',
    guide: { text: 'scripts Outputs', link: '/tooling/scripts' },
  },
  workflows: {
    file: 'reference/generated-workflows.md',
    title: 'Generated Workflow Index',
    description: 'GitHub workflow files discovered under `.github/workflows/` are listed here.',
    guide: { text: 'CI and Automation', link: '/ci-and-automation' },
  },
};

const modulePurposeOverrides = {
  'hosts/modules/conf/ssh-remote-bind.nix':
    'Defines a systemd-backed reverse SSH tunnel service with reconnect behavior and bind controls.',
  'hosts/modules/darwin/ollama.nix':
    'Defines a nix-darwin launchd service for running the Ollama daemon with configurable host, port, models path, and environment.',
  'hosts/modules/darwin/llama-server.nix':
    'Defines nix-darwin launchd services for one or more `llama-server` instances with per-model configuration.',
  'hosts/modules/darwin/mlx-vlm-api.nix':
    'Defines nix-darwin launchd services for `mlx-vlm-api` instances with model, host, and port configuration.',
  'hosts/modules/servers/infinity.nix':
    'Defines a NixOS service module for Infinity embedding and reranking APIs, including model lists and runtime wiring.',
  'hosts/modules/servers/minifluxng.nix':
    'Defines a hardened NixOS module for Miniflux with database, OIDC, TLS, and maintenance helper services.',
  'hosts/modules/servers/obligator.nix':
    'Defines a NixOS service module for the self-hosted OpenID Connect server `obligator`.',
  'hosts/modules/servers/poglets.nix':
    'Defines a NixOS service module for running `poglets` as a managed daemon with secret and environment support.',
};

const packagePurposeOverrides = {
  'pkgs/ai/chatbot-ui.nix': 'Builds `chatbot-ui` as a runnable Next.js application for OpenAI-compatible backends.',
  'pkgs/ai/genai-toolbox.nix': 'Builds `genai-toolbox`, an MCP server focused on database integrations.',
  'pkgs/cli/mica.nix': 'Builds the `mica` terminal UI for managing Nix environments.',
  'pkgs/cli/slack-notifier.nix': 'Builds a CLI that posts messages and attachments to Slack incoming webhooks.',
  'pkgs/cloud/fake-gcs-server.nix': 'Builds a local Google Cloud Storage emulator service.',
  'pkgs/cloud/gcsproxy.nix': 'Builds a reverse proxy for Google Cloud Storage.',
  'pkgs/mcp/loki-mcp.nix': 'Builds an MCP server for Loki queries and log workflows.',
  'pkgs/mcp/ntfy-mcp.nix': 'Builds an MCP server for `ntfy` notifications.',
  'pkgs/mcp/prom-mcp.nix': 'Builds an MCP server for Prometheus queries and metrics workflows.',
  'pkgs/server/obligator.nix': 'Builds the `obligator` self-hosted OpenID Connect server.',
  'pkgs/server/poglets.nix': 'Builds `poglets`, a TCP tunneling system with shell completion support.',
  'pkgs/server/vercel-log-drain.nix': 'Builds `vercel-log-drain`, a service for exporting Vercel logs to additional outputs.',
  'pkgs/uv/vllm.nix': 'Builds a packaged `vllm` inference and serving runtime for large language models.',
};

const scriptPurposeOverrides = {
  check_doc_links: 'Scans markdown files for broken local links.',
  check_readme_index: 'Compares README directory indexes against actual directory contents.',
  ci_cache: 'Sets up credentials and runs the repository cache helper for CI builds.',
};

function toPosix(value) {
  return value.split(path.sep).join('/');
}

function ensureDir(absoluteDir) {
  fs.mkdirSync(absoluteDir, { recursive: true });
}

function writeFile(relativePath, contents) {
  const absolutePath = path.join(docsRoot, relativePath);
  ensureDir(path.dirname(absolutePath));
  fs.writeFileSync(absolutePath, contents);
}

function cleanGeneratedArtifacts() {
  fs.rmSync(path.join(referenceRoot, 'generated-repo-index.json'), { force: true });
  for (const dirName of generatedEntryDirs) {
    fs.rmSync(path.join(referenceRoot, dirName), { recursive: true, force: true });
  }
}

function walkFiles(rootDir, predicate) {
  if (!fs.existsSync(rootDir)) {
    return [];
  }

  const files = [];
  const stack = [rootDir];
  while (stack.length > 0) {
    const current = stack.pop();
    const entries = fs.readdirSync(current, { withFileTypes: true });
    for (const entry of entries) {
      if (entry.name.startsWith('.')) {
        continue;
      }
      const absolutePath = path.join(current, entry.name);
      if (entry.isDirectory()) {
        stack.push(absolutePath);
        continue;
      }
      if (entry.isFile() && predicate(absolutePath)) {
        files.push(absolutePath);
      }
    }
  }

  return files.sort((a, b) => toPosix(path.relative(repoRoot, a)).localeCompare(toPosix(path.relative(repoRoot, b))));
}

function repoPathFromAbsolute(absolutePath) {
  return toPosix(path.relative(repoRoot, absolutePath));
}

function absolutePathForRepoPath(repoPath) {
  return path.join(repoRoot, ...repoPath.split('/'));
}

function repoPathExists(repoPath) {
  return fs.existsSync(absolutePathForRepoPath(repoPath));
}

function readRepoText(repoPath) {
  try {
    return fs.readFileSync(absolutePathForRepoPath(repoPath), 'utf8');
  } catch {
    return '';
  }
}

function pickFirstMatch(text, patterns) {
  for (const pattern of patterns) {
    const match = text.match(pattern);
    if (match && match[1]) {
      return match[1].trim();
    }
  }
  return null;
}

function extractLocalNixReferences(text) {
  return Array.from(new Set(text.match(/\.\/[A-Za-z0-9._/-]+\.nix/g) || []));
}

function extractNixMetadata(text) {
  return {
    description: pickFirstMatch(text, [/meta\.description\s*=\s*"([^"]+)"/, /description\s*=\s*"([^"]+)"/]),
    pname: pickFirstMatch(text, [/\bpname\s*=\s*"([^"]+)"/, /\bname\s*=\s*"([^"]+)"/]),
    version: pickFirstMatch(text, [/\bversion\s*=\s*"([^"]+)"/]),
    mainProgram: pickFirstMatch(text, [/\bmainProgram\s*=\s*"([^"]+)"/]),
    localNixRefs: extractLocalNixReferences(text),
  };
}

function getIndentedBlockLines(text, key) {
  const lines = text.split(/\r?\n/);
  const keyPattern = new RegExp(`^${key}:\\s*$`);
  const startIndex = lines.findIndex((line) => keyPattern.test(line));
  if (startIndex === -1) {
    return [];
  }

  const blockLines = [];
  for (let index = startIndex + 1; index < lines.length; index += 1) {
    const line = lines[index];
    if (line.trim() === '') {
      blockLines.push(line);
      continue;
    }
    if (!line.startsWith(' ') && !line.startsWith('\t')) {
      break;
    }
    blockLines.push(line);
  }
  return blockLines;
}

function extractWorkflowMetadata(text) {
  const workflowName = pickFirstMatch(text, [/^name:\s*["']?([^"'\n]+)["']?\s*$/m]);
  const events = [];

  const flowStyleEvents = text.match(/^on:\s*{(.+)}\s*$/m);
  if (flowStyleEvents && flowStyleEvents[1]) {
    const items = [];
    let current = '';
    let curlyDepth = 0;
    let bracketDepth = 0;
    for (const char of flowStyleEvents[1]) {
      if (char === '{') {
        curlyDepth += 1;
      } else if (char === '}') {
        curlyDepth -= 1;
      } else if (char === '[') {
        bracketDepth += 1;
      } else if (char === ']') {
        bracketDepth -= 1;
      }

      if (char === ',' && curlyDepth === 0 && bracketDepth === 0) {
        items.push(current);
        current = '';
        continue;
      }
      current += char;
    }
    if (current.trim() !== '') {
      items.push(current);
    }

    for (const item of items) {
      const trimmed = item.trim();
      if (trimmed === '') {
        continue;
      }
      const key = trimmed.includes(':') ? trimmed.split(':')[0].trim() : trimmed;
      if (key !== '') {
        events.push(key);
      }
    }
  }

  const inlineEvents = text.match(/^on:\s*\[([^\]]+)\]\s*$/m);
  if (inlineEvents && inlineEvents[1]) {
    events.push(
      ...inlineEvents[1]
        .split(',')
        .map((eventName) => eventName.trim().replace(/^['"]|['"]$/g, ''))
        .filter(Boolean),
    );
  } else if (events.length === 0) {
    const singleEvent = text.match(/^on:\s*([A-Za-z0-9_/-]+)\s*$/m);
    if (singleEvent && singleEvent[1]) {
      events.push(singleEvent[1]);
    } else {
      const onBlockLines = getIndentedBlockLines(text, 'on');
      for (const line of onBlockLines) {
        const eventMatch = line.match(/^[ \t]{2}([A-Za-z0-9_/-]+):\s*$/);
        if (eventMatch && eventMatch[1]) {
          events.push(eventMatch[1]);
        }
      }
    }
  }

  const jobs = [];
  const jobsBlockLines = getIndentedBlockLines(text, 'jobs');
  for (const line of jobsBlockLines) {
    const jobMatch = line.match(/^[ \t]{2}([A-Za-z0-9_-]+):\s*$/);
    if (jobMatch && jobMatch[1]) {
      jobs.push(jobMatch[1]);
    }
  }

  return {
    workflowName,
    events: Array.from(new Set(events)),
    jobs: Array.from(new Set(jobs)),
  };
}

function toBlobUrl(repoPath) {
  return `${repoBlobBaseUrl}/${repoPath}`;
}

function toTreeUrl(repoPath) {
  return `${repoTreeBaseUrl}/${repoPath}`;
}

function formatSource(repoPath, url) {
  return `[source](${url})`;
}

function friendlyModuleLabel(repoPath) {
  const parts = repoPath.split('/');
  return `${parts[2]}/${path.basename(repoPath, '.nix')}`;
}

function friendlyPackageLabel(repoPath) {
  const parts = repoPath.split('/');
  const category = parts[1] || 'misc';
  const remainder = parts.slice(2).join('/').replace(/\/default\.nix$/, '').replace(/\.nix$/, '');
  return `${category}/${remainder}`;
}

function friendlyWrapperLabel(repoPath) {
  if (repoPath === 'mods/hms.nix') {
    return 'hms';
  }
  if (repoPath === 'mods/hax.nix') {
    return 'hax';
  }
  return `pog/${path.basename(repoPath, '.nix')}`;
}

function friendlyWorkflowLabel(repoPath) {
  return path.basename(repoPath, path.extname(repoPath));
}

function summarizeModule(repoPath) {
  if (modulePurposeOverrides[repoPath]) {
    return modulePurposeOverrides[repoPath];
  }

  const area = repoPath.split('/')[2] || 'general';
  const name = path.basename(repoPath, '.nix');
  return `Provides reusable \`${area}\` module logic in \`${name}\`.`;
}

function summarizePackage(repoPath) {
  if (packagePurposeOverrides[repoPath]) {
    return packagePurposeOverrides[repoPath];
  }

  const text = readRepoText(repoPath);
  const metadata = extractNixMetadata(text);
  const fallbackName = repoPath.endsWith('/default.nix')
    ? path.basename(path.dirname(repoPath))
    : path.basename(repoPath, '.nix');
  const name = metadata.pname || fallbackName;
  if (metadata.description) {
    return `Builds \`${name}\`: ${metadata.description}`;
  }

  return `Builds and exposes package \`${name}\` from this repo's custom package set.`;
}

function summarizeWrapper(repoPath) {
  if (repoPath === 'mods/hms.nix') {
    return 'Defines the `hms` and `hmx` rebuild helpers for repo-managed machines.';
  }
  if (repoPath === 'mods/hax.nix') {
    return 'Provides lower-level helper primitives used by other repo tooling.';
  }

  const domain = path.basename(repoPath, '.nix');
  return `Defines ` + '`pog`' + ` commands for the \`${domain}\` domain.`;
}

function summarizeScript(entry) {
  if (scriptPurposeOverrides[entry.attr]) {
    return scriptPurposeOverrides[entry.attr];
  }
  return `Defines the script output \`${entry.binary}\` for repository automation.`;
}

function summarizeWorkflow(repoPath) {
  const metadata = extractWorkflowMetadata(readRepoText(repoPath));
  const jobsText =
    metadata.jobs.length > 0
      ? `jobs ${metadata.jobs.map((value) => `\`${value}\``).join(', ')}`
      : 'configured jobs';
  const triggersText =
    metadata.events.length > 0
      ? ` on ${metadata.events.map((value) => `\`${value}\``).join(', ')}`
      : '';
  return `Runs ${jobsText}${triggersText} in GitHub Actions.`;
}

function collectHosts() {
  const hostsRoot = path.join(repoRoot, 'hosts');
  if (!fs.existsSync(hostsRoot)) {
    return [];
  }

  return fs
    .readdirSync(hostsRoot, { withFileTypes: true })
    .filter((entry) => entry.isDirectory())
    .map((entry) => entry.name)
    .filter((name) => !name.startsWith('.'))
    .filter((name) => name !== 'modules')
    .filter((name) => fs.existsSync(path.join(hostsRoot, name, 'configuration.nix')))
    .sort((a, b) => a.localeCompare(b))
    .map((name) => {
      const repoPath = `hosts/${name}`;
      const configRepoPath = `${repoPath}/configuration.nix`;
      const hardwareRepoPath = `${repoPath}/hardware-configuration.nix`;
      const readmeRepoPath = `${repoPath}/README.md`;
      const hasHardwareConfig = repoPathExists(hardwareRepoPath);
      const hasReadme = repoPathExists(readmeRepoPath);
      return {
        name,
        repoPath,
        configRepoPath,
        hardwareRepoPath,
        readmeRepoPath,
        hasHardwareConfig,
        hasReadme,
        group: hasHardwareConfig ? 'NixOS-style hosts' : 'nix-darwin and custom-style hosts',
      };
    });
}

function collectModules() {
  return walkFiles(path.join(repoRoot, 'hosts/modules'), (absolutePath) => absolutePath.endsWith('.nix')).map((absolutePath) => {
    const repoPath = repoPathFromAbsolute(absolutePath);
    return {
      label: friendlyModuleLabel(repoPath),
      group: repoPath.split('/')[2] || 'other',
      repoPath,
      repoUrl: toBlobUrl(repoPath),
      summary: summarizeModule(repoPath),
    };
  });
}

function collectPackages() {
  return walkFiles(path.join(repoRoot, 'pkgs'), (absolutePath) => absolutePath.endsWith('.nix')).map((absolutePath) => {
    const repoPath = repoPathFromAbsolute(absolutePath);
    return {
      label: friendlyPackageLabel(repoPath),
      group: repoPath.split('/')[1] || 'other',
      repoPath,
      repoUrl: toBlobUrl(repoPath),
      summary: summarizePackage(repoPath),
    };
  });
}

function collectWrappers() {
  const wrapperPaths = [];
  const hmsPath = path.join(repoRoot, 'mods/hms.nix');
  const haxPath = path.join(repoRoot, 'mods/hax.nix');

  if (fs.existsSync(hmsPath)) {
    wrapperPaths.push(hmsPath);
  }
  if (fs.existsSync(haxPath)) {
    wrapperPaths.push(haxPath);
  }

  wrapperPaths.push(...walkFiles(path.join(repoRoot, 'mods/pog'), (absolutePath) => absolutePath.endsWith('.nix')));

  return Array.from(new Set(wrapperPaths.map((absolutePath) => repoPathFromAbsolute(absolutePath))))
    .sort((a, b) => a.localeCompare(b))
    .map((repoPath) => ({
      label: friendlyWrapperLabel(repoPath),
      group: repoPath.startsWith('mods/pog/') ? 'pog domains' : 'repo helpers',
      repoPath,
      repoUrl: toBlobUrl(repoPath),
      summary: summarizeWrapper(repoPath),
    }));
}

function collectScripts() {
  const scriptsPath = path.join(repoRoot, 'scripts.nix');
  if (!fs.existsSync(scriptsPath)) {
    return [];
  }

  const source = fs.readFileSync(scriptsPath, 'utf8');
  const pattern = /^\s*([a-zA-Z0-9_]+)\s*=\s*writeBashBinChecked\s+"([^"]+)"\s+''([\s\S]*?)'';/gm;
  const entries = [];

  for (const match of source.matchAll(pattern)) {
    const attr = match[1];
    if (excludedScripts.has(attr)) {
      continue;
    }

    entries.push({
      attr,
      binary: match[2],
      group: 'script outputs',
      repoPath: 'scripts.nix',
      repoUrl: toBlobUrl('scripts.nix'),
      summary: summarizeScript({ attr, binary: match[2] }),
    });
  }

  return entries.sort((a, b) => a.attr.localeCompare(b.attr));
}

function collectWorkflows() {
  return walkFiles(path.join(repoRoot, '.github/workflows'), (absolutePath) => /\.(ya?ml)$/i.test(absolutePath)).map(
    (absolutePath) => {
      const repoPath = repoPathFromAbsolute(absolutePath);
      return {
        label: friendlyWorkflowLabel(repoPath),
        group: 'GitHub Actions workflows',
        repoPath,
        repoUrl: toBlobUrl(repoPath),
        summary: summarizeWorkflow(repoPath),
      };
    },
  );
}

function groupEntries(entries) {
  const map = new Map();
  for (const entry of entries) {
    const groupName = entry.group || 'other';
    const bucket = map.get(groupName) || [];
    bucket.push(entry);
    map.set(groupName, bucket);
  }

  return Array.from(map.entries())
    .sort((a, b) => a[0].localeCompare(b[0]))
    .map(([groupName, groupEntriesValue]) => ({
      name: groupName,
      entries: groupEntriesValue.sort((a, b) => {
        const left = a.label || a.attr || a.name;
        const right = b.label || b.attr || b.name;
        return left.localeCompare(right);
      }),
    }));
}

function renderGeneratedHeader(kind, total) {
  const section = sections[kind];
  return [
    `# ${section.title}`,
    '',
    section.description,
    '',
    `Curated guide: [${section.guide.text}](${section.guide.link})`,
    '',
    `Total entries: **${total}**`,
    '',
    'Regenerate from `docs/` with `bun run docs:gen`.',
    '',
  ];
}

function renderHostsPage(entries) {
  const lines = renderGeneratedHeader('hosts', entries.length);
  for (const group of groupEntries(entries)) {
    lines.push(`## ${group.name} (${group.entries.length})`, '');
    for (const entry of group.entries) {
      const links = [
        `[config](${toBlobUrl(entry.configRepoPath)})`,
        entry.hasHardwareConfig ? `[hardware](${toBlobUrl(entry.hardwareRepoPath)})` : null,
        entry.hasReadme ? `[README](${toBlobUrl(entry.readmeRepoPath)})` : null,
        formatSource(entry.repoPath, toTreeUrl(entry.repoPath)),
      ]
        .filter(Boolean)
        .join(', ');
      const summary = entry.hasHardwareConfig ? 'NixOS host.' : 'nix-darwin or custom-style host.';
      lines.push(`- \`${entry.name}\`, ${summary} ${links}`);
    }
    lines.push('');
  }
  return `${lines.join('\n')}\n`;
}

function renderGroupedPage(kind, entries) {
  const lines = renderGeneratedHeader(kind, entries.length);
  for (const group of groupEntries(entries)) {
    lines.push(`## ${group.name} (${group.entries.length})`, '');
    for (const entry of group.entries) {
      const label = entry.label || entry.attr;
      lines.push(`- \`${label}\`, ${entry.summary} ${formatSource(entry.repoPath, entry.repoUrl)}`);
    }
    lines.push('');
  }
  return `${lines.join('\n')}\n`;
}

function writeGeneratedFiles() {
  ensureDir(referenceRoot);
  cleanGeneratedArtifacts();

  const byKind = {
    hosts: collectHosts(),
    modules: collectModules(),
    packages: collectPackages(),
    wrappers: collectWrappers(),
    scripts: collectScripts(),
    workflows: collectWorkflows(),
  };

  writeFile(sections.hosts.file, renderHostsPage(byKind.hosts));
  writeFile(sections.modules.file, renderGroupedPage('modules', byKind.modules));
  writeFile(sections.packages.file, renderGroupedPage('packages', byKind.packages));
  writeFile(sections.wrappers.file, renderGroupedPage('wrappers', byKind.wrappers));
  writeFile(sections.scripts.file, renderGroupedPage('scripts', byKind.scripts));
  writeFile(sections.workflows.file, renderGroupedPage('workflows', byKind.workflows));

  process.stdout.write(
    [
      'Generated docs reference indexes:',
      `- hosts: ${byKind.hosts.length}`,
      `- modules: ${byKind.modules.length}`,
      `- packages: ${byKind.packages.length}`,
      `- wrappers: ${byKind.wrappers.length}`,
      `- scripts: ${byKind.scripts.length}`,
      `- workflows: ${byKind.workflows.length}`,
    ].join('\n') + '\n',
  );
}

writeGeneratedFiles();
