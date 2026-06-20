#!/usr/bin/env node

import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { homedir } from 'node:os';

// Config lives with the skill in the repo. No symlink, no XDG path.
const DEFAULT_CONFIG = new URL('../config/config.json', import.meta.url).pathname;

function usage() {
  console.log(`Usage:
  work-migrate list-pipelines [--config path]
  work-migrate validate-config [--config path]
  work-migrate prepare <pipeline> [--config path] [--limit n] --out path
  work-migrate apply-plan <path> [--config path] [--apply]
  work-migrate run <pipeline> [--config path] [--limit n] [--apply]
  work-migrate run-all [--config path] [--group name] [--limit n] [--apply]

Defaults to dry-run. Use prepare/apply-plan for agent-curated issue creation.
Raw run --apply is blocked unless --allow-raw is supplied.

Credential locations:
  Notion: ~/.config/notion/api_key or NOTION_API_KEY
  GitHub: gh CLI auth
`);
}

function parseArgs(argv) {
  const args = { _: [] };
  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i];
    if (arg === '--apply') {
      args.apply = true;
    } else if (arg === '--config') {
      args.config = argv[++i];
    } else if (arg === '--limit') {
      args.limit = Number(argv[++i]);
    } else if (arg === '--group') {
      args.group = argv[++i];
    } else if (arg === '--out') {
      args.out = argv[++i];
    } else if (arg === '--allow-raw') {
      args.allowRaw = true;
    } else if (arg === '--help' || arg === '-h') {
      args.help = true;
    } else {
      args._.push(arg);
    }
  }
  return args;
}

function expandPath(path) {
  if (!path) return path;
  if (path === '~') return homedir();
  if (path.startsWith('~/')) return resolve(homedir(), path.slice(2));
  return resolve(path);
}

function readJson(path) {
  return JSON.parse(readFileSync(path, 'utf8'));
}

function loadConfig(configPath) {
  const path = expandPath(configPath || DEFAULT_CONFIG);
  if (!existsSync(path)) {
    throw new Error(`Config not found: ${path}\nCreate one from skills/work-migration/config/work-migrate.example.json.`);
  }
  return { path, config: readJson(path) };
}

function loadState(statePath) {
  const path = expandPath(statePath || '~/.local/state/work-migrate/state.json');
  if (!existsSync(path)) return { path, state: { migrations: {} } };
  return { path, state: readJson(path) };
}

function saveState(path, state) {
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, `${JSON.stringify(state, null, 2)}\n`);
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, {
    encoding: 'utf8',
    stdio: ['ignore', 'pipe', 'pipe'],
    ...options,
  });
  if (result.status !== 0) {
    const detail = (result.stderr || result.stdout || '').trim();
    throw new Error(`${command} ${args.join(' ')} failed${detail ? `:\n${detail}` : ''}`);
  }
  return result.stdout;
}

function readSecretFile(path) {
  const expanded = expandPath(path);
  if (!existsSync(expanded)) return null;
  return readFileSync(expanded, 'utf8').trim();
}

function sourceKey(item) {
  return `${item.source.type}:${item.source.id}`;
}

function normalizeText(value) {
  if (!value) return '';
  return String(value).replace(/\r\n/g, '\n').trim();
}

function formatBody(item) {
  if (item.body) return item.body;
  const parts = [];
  if (item.notes) {
    parts.push(item.notes);
  }
  if (item.checklist?.length) {
    parts.push(`Checklist:\n${item.checklist.map((entry) => `- [${entry.completed ? 'x' : ' '}] ${entry.title}`).join('\n')}`);
  }
  parts.push(`Source: ${item.source.type}:${item.source.id}`);
  if (item.source.url) {
    parts.push(`Source URL: ${item.source.url}`);
  }
  return parts.join('\n\n');
}

function ensureGitHubLabels(destination) {
  if (!destination.labels?.length) return;
  const raw = run('gh', ['label', 'list', '--repo', destination.repo, '--json', 'name', '--limit', '1000']);
  const existing = new Set(JSON.parse(raw || '[]').map((label) => label.name));
  for (const label of destination.labels) {
    if (existing.has(label)) continue;
    run('gh', [
      'label',
      'create',
      label,
      '--repo',
      destination.repo,
      '--color',
      '6f42c1',
      '--description',
      'Imported from a private task source',
    ]);
    existing.add(label);
  }
}

function thingsItems(source, limit) {
  if (Array.isArray(source.ids) && source.ids.length) {
    return source.ids.slice(0, limit || source.ids.length).map((id) => {
      const raw = run('things', ['show', '--id', id, '--json']);
      const task = JSON.parse(raw);
      return {
        title: task.title,
        notes: normalizeText(task.notes),
        checklist: Array.isArray(task.checklist)
          ? task.checklist.map((entry) => ({ title: entry.title, completed: Boolean(entry.completed) }))
          : [],
        source: {
          type: 'things',
          id: task.uuid || task.id,
          url: task.url || null,
          raw: task,
        },
      };
    }).filter((item) => item.title && item.source.id);
  }

  const args = ['tasks', '--format', 'json'];
  if (source.project) args.push('--project', source.project);
  if (source.area) args.push('--area', source.area);
  if (source.tag) args.push('--tag', source.tag);
  if (source.query) args.push('--query', source.query);
  if (limit) args.push('--limit', String(limit));

  const raw = run('things', args);
  const parsed = JSON.parse(raw || '[]');
  return parsed.map((task) => ({
    title: task.title,
    notes: normalizeText(task.notes),
    checklist: Array.isArray(task.checklist)
      ? task.checklist.map((entry) => ({ title: entry.title, completed: Boolean(entry.completed) }))
      : [],
    source: {
      type: 'things',
      id: task.uuid || task.id,
      url: task.url || null,
      raw: task,
    },
  })).filter((item) => item.title && item.source.id);
}

function richTextToPlain(value) {
  if (!Array.isArray(value)) return '';
  return value.map((part) => part.plain_text || part.text?.content || '').join('');
}

function propertyToPlain(property) {
  if (!property) return '';
  if (property.type === 'title') return richTextToPlain(property.title);
  if (property.type === 'rich_text') return richTextToPlain(property.rich_text);
  if (property.type === 'status') return property.status?.name || '';
  if (property.type === 'select') return property.select?.name || '';
  if (property.type === 'multi_select') return property.multi_select?.map((item) => item.name).join(', ') || '';
  if (property.type === 'date') return property.date?.start || '';
  if (property.type === 'url') return property.url || '';
  if (property.type === 'checkbox') return property.checkbox ? 'true' : 'false';
  if (property.type === 'number') return property.number === null ? '' : String(property.number);
  return '';
}

function notionPropertySummary(properties, propertyNames) {
  const names = propertyNames || Object.keys(properties || {});
  const lines = [];
  for (const name of names) {
    const property = properties?.[name];
    if (!property) continue;
    const value = propertyToPlain(property);
    if (value === '' || value === false) continue;
    lines.push(`- ${name}: ${value}`);
  }
  return lines.length ? `Notion properties:\n${lines.join('\n')}` : '';
}

async function notionRequest(config, path, body = undefined) {
  const token = process.env.NOTION_API_KEY || readSecretFile('~/.config/notion/api_key');
  if (!token) {
    throw new Error('Missing Notion token. Set NOTION_API_KEY or ~/.config/notion/api_key.');
  }

  const response = await fetch(`https://api.notion.com/v1${path}`, {
    method: body ? 'POST' : 'GET',
    headers: {
      Authorization: `Bearer ${token}`,
      'Notion-Version': config.notionVersion || '2026-03-11',
      'Content-Type': 'application/json',
    },
    body: body ? JSON.stringify(body) : undefined,
  });

  if (!response.ok) {
    throw new Error(`Notion ${path} failed: ${response.status} ${await response.text()}`);
  }
  return response.json();
}

async function notionItems(source, limit, defaults) {
  let cursor = null;
  const results = [];
  do {
    const body = {
      page_size: Math.min(100, Math.max(1, limit ? limit - results.length : 100)),
      ...(source.filter ? { filter: source.filter } : {}),
      ...(source.sorts ? { sorts: source.sorts } : {}),
      ...(cursor ? { start_cursor: cursor } : {}),
    };
    const page = await notionRequest(defaults, `/data_sources/${source.dataSourceId}/query`, body);
    results.push(...page.results);
    cursor = page.has_more && (!limit || results.length < limit) ? page.next_cursor : null;
  } while (cursor);

  const titleProperty = source.titleProperty || 'Name';
  const notesProperty = source.notesProperty || 'Notes';
  return results.slice(0, limit || results.length).map((page) => ({
    title: propertyToPlain(page.properties?.[titleProperty]) || `Notion page ${page.id}`,
    notes: [
      normalizeText(propertyToPlain(page.properties?.[notesProperty])),
      notionPropertySummary(page.properties, source.includeProperties),
    ].filter(Boolean).join('\n\n'),
    checklist: [],
    source: {
      type: 'notion',
      id: page.id,
      url: page.url || null,
      raw: page,
    },
  }));
}

async function loadSourceItems(source, limit, defaults) {
  if (source.type === 'things') return thingsItems(source, limit);
  if (source.type === 'notion') return notionItems(source, limit, defaults);
  throw new Error(`Unsupported source type: ${source.type}`);
}

function createGitHubIssue(destination, item) {
  const labels = [...new Set([...(destination.labels || []), ...(item.labels || [])])];
  ensureGitHubLabels({ ...destination, labels });
  const args = ['issue', 'create', '--repo', destination.repo, '--title', item.title, '--body', formatBody(item)];
  for (const label of labels) args.push('--label', label);
  for (const assignee of item.assignees || []) args.push('--assignee', assignee);
  if (item.milestone) args.push('--milestone', item.milestone);
  const out = run('gh', args).trim();
  return { id: out, url: out };
}

async function createAzureWorkItem(destination, item) {
  const pat = process.env.AZURE_DEVOPS_PAT;
  if (!pat) throw new Error('Missing AZURE_DEVOPS_PAT.');
  const url = `https://dev.azure.com/${encodeURIComponent(destination.organization)}/${encodeURIComponent(destination.project)}/_apis/wit/workitems/$${encodeURIComponent(destination.workItemType || 'Task')}?api-version=7.1`;
  const ops = [
    { op: 'add', path: '/fields/System.Title', value: item.title },
    { op: 'add', path: '/fields/System.Description', value: formatBody(item).replace(/\n/g, '<br>') },
  ];
  if (destination.areaPath) ops.push({ op: 'add', path: '/fields/System.AreaPath', value: destination.areaPath });
  if (destination.iterationPath) ops.push({ op: 'add', path: '/fields/System.IterationPath', value: destination.iterationPath });
  if (destination.tags?.length) ops.push({ op: 'add', path: '/fields/System.Tags', value: destination.tags.join('; ') });

  const response = await fetch(url, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(`:${pat}`).toString('base64')}`,
      'Content-Type': 'application/json-patch+json',
    },
    body: JSON.stringify(ops),
  });
  if (!response.ok) {
    throw new Error(`Azure DevOps create failed: ${response.status} ${await response.text()}`);
  }
  const json = await response.json();
  return { id: String(json.id), url: json._links?.html?.href || json.url };
}

async function createJiraIssue(destination, item) {
  const email = process.env.JIRA_EMAIL;
  const token = process.env.JIRA_API_TOKEN;
  if (!email || !token) throw new Error('Missing JIRA_EMAIL or JIRA_API_TOKEN.');
  const response = await fetch(`${destination.baseUrl.replace(/\/$/, '')}/rest/api/3/issue`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${Buffer.from(`${email}:${token}`).toString('base64')}`,
      Accept: 'application/json',
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      fields: {
        project: { key: destination.projectKey },
        summary: item.title,
        issuetype: { name: destination.issueType || 'Task' },
        labels: destination.labels || [],
        description: {
          type: 'doc',
          version: 1,
          content: [{ type: 'paragraph', content: [{ type: 'text', text: formatBody(item) }] }],
        },
      },
    }),
  });
  if (!response.ok) {
    throw new Error(`Jira create failed: ${response.status} ${await response.text()}`);
  }
  const json = await response.json();
  return { id: json.key, url: `${destination.baseUrl.replace(/\/$/, '')}/browse/${json.key}` };
}

async function createDestinationItem(destination, item) {
  if (destination.type === 'github') return createGitHubIssue(destination, item);
  if (destination.type === 'azure-devops') return createAzureWorkItem(destination, item);
  if (destination.type === 'jira') return createJiraIssue(destination, item);
  throw new Error(`Unsupported destination type: ${destination.type}`);
}

function issuePlanPath(path) {
  if (!path) throw new Error('Missing issue plan path.');
  return expandPath(path);
}

function draftIssueBody(item) {
  const sourceBody = formatBody(item);
  return [
    '<!-- Rewrite this draft before apply-plan. Keep the source provenance at the bottom. -->',
    '',
    '## Problem',
    '',
    '',
    '## Desired outcome',
    '',
    '',
    '## Notes',
    '',
    sourceBody,
  ].join('\n');
}

function issueDraftFor(pipelineName, pipeline, item) {
  return {
    pipeline: pipelineName,
    sourceKey: sourceKey(item),
    source: item.source,
    destination: pipeline.destination,
    afterCreate: pipeline.afterCreate || null,
    raw: {
      title: item.title,
      notes: item.notes || '',
      checklist: item.checklist || [],
    },
    issue: {
      title: '',
      body: draftIssueBody(item),
      labels: pipeline.destination.labels || [],
      assignees: [],
      milestone: null,
    },
  };
}

async function prepareIssuePlan(config, name, options) {
  const pipeline = config.pipelines?.[name];
  if (!pipeline) throw new Error(`Unknown pipeline: ${name}`);
  const limit = options.limit || pipeline.limit || config.defaults?.limit || 25;
  const { state } = loadState(config.statePath);
  const items = await loadSourceItems(pipeline.source, limit, config.defaults || {});
  const pending = items.filter((item) => !state.migrations[sourceKey(item)]);
  const plan = {
    version: 1,
    generatedAt: new Date().toISOString(),
    mode: 'agent-curated-issue-plan',
    instructions: [
      'An LLM/orchestrator must rewrite each issue before apply-plan.',
      'Set issue.title to a concise GitHub issue title, not a raw task dump.',
      'Rewrite issue.body with problem, context, acceptance criteria, and implementation notes when useful.',
      'Adjust labels, assignees, and milestone as appropriate for the destination repo.',
      'Leave sourceKey/source unchanged so the state ledger and Things cleanup remain correct.',
    ],
    items: pending.map((item) => issueDraftFor(name, pipeline, item)),
  };
  const outPath = issuePlanPath(options.out);
  mkdirSync(dirname(outPath), { recursive: true });
  writeFileSync(outPath, `${JSON.stringify(plan, null, 2)}\n`);
  console.log(`Prepared ${plan.items.length} issue draft(s): ${outPath}`);
}

function validateIssuePlanItem(entry) {
  const title = normalizeText(entry.issue?.title);
  const body = normalizeText(entry.issue?.body);
  if (!entry.source?.type || !entry.source?.id) {
    throw new Error(`${entry.sourceKey || 'plan item'}: missing source identity`);
  }
  if (!entry.destination?.type) {
    throw new Error(`${entry.sourceKey}: missing destination`);
  }
  if (!title) {
    throw new Error(`${entry.sourceKey}: issue.title is empty. The orchestrator must write a real title.`);
  }
  if (title === normalizeText(entry.raw?.title)) {
    throw new Error(`${entry.sourceKey}: issue.title still matches the raw task title. Rewrite it before apply-plan.`);
  }
  if (!body || body.includes('<!-- Rewrite this draft before apply-plan.')) {
    throw new Error(`${entry.sourceKey}: issue.body still contains the draft template. Rewrite it before apply-plan.`);
  }
}

async function applyIssuePlan(config, planPath, options) {
  const plan = readJson(issuePlanPath(planPath));
  if (!Array.isArray(plan.items)) throw new Error('Issue plan must contain an items array.');
  const { path: statePath, state } = loadState(config.statePath);
  const pending = plan.items.filter((entry) => !state.migrations[entry.sourceKey || sourceKey({ source: entry.source })]);
  console.log(`Issue plan: ${planPath}`);
  console.log(`Loaded: ${plan.items.length}; pending: ${pending.length}; mode: ${options.apply ? 'apply' : 'dry-run'}`);

  for (const entry of pending) {
    validateIssuePlanItem(entry);
    const source = entry.source;
    const item = {
      title: normalizeText(entry.issue.title),
      body: normalizeText(entry.issue.body),
      labels: entry.issue.labels || [],
      assignees: entry.issue.assignees || [],
      milestone: entry.issue.milestone || null,
      source,
    };
    if (!options.apply) {
      console.log(`DRY ${entry.sourceKey} -> ${entry.destination.type}: ${item.title}`);
      continue;
    }
    const created = await createDestinationItem(entry.destination, item);
    state.migrations[entry.sourceKey] = {
      createdAt: new Date().toISOString(),
      pipeline: entry.pipeline || null,
      source,
      destination: {
        type: entry.destination.type,
        id: created.id,
        url: created.url,
      },
      title: item.title,
    };
    saveState(statePath, state);
    markThingsCreated({ source }, created, entry.afterCreate);
    console.log(`CREATED ${entry.sourceKey} -> ${created.url || created.id}`);
  }

  if (!options.apply) {
    console.log('No remote changes made. Re-run apply-plan with --apply after reviewing the issue plan.');
  }
}

function markThingsCreated(item, created, afterCreate) {
  if (item.source.type !== 'things' || !afterCreate?.things) return;
  const marker = `Migrated to ${created.url || created.id}`;
  const args = ['update', '--id', item.source.id];
  if (afterCreate.things.appendNote !== false) {
    args.push('--append-notes', marker);
  }
  if (afterCreate.things.tags?.length) {
    args.push('--add-tags', afterCreate.things.tags.join(','));
  }
  if (afterCreate.things.complete) {
    args.push('--completed');
  }
  if (afterCreate.things.when) {
    args.push('--when', afterCreate.things.when);
  }
  run('things', args);
}

async function runPipeline(config, name, options) {
  if (options.apply && !options.allowRaw) {
    throw new Error('Raw run --apply is disabled. Use prepare, let the orchestrator rewrite the issue plan, then apply-plan --apply. Use --allow-raw only for emergency transport tests.');
  }
  const pipeline = config.pipelines?.[name];
  if (!pipeline) {
    throw new Error(`Unknown pipeline: ${name}`);
  }

  const limit = options.limit || pipeline.limit || config.defaults?.limit || 25;
  const { path: statePath, state } = loadState(config.statePath);
  const items = await loadSourceItems(pipeline.source, limit, config.defaults || {});
  const pending = items.filter((item) => !state.migrations[sourceKey(item)]);

  console.log(`Pipeline: ${name}`);
  console.log(`Loaded: ${items.length}; pending: ${pending.length}; mode: ${options.apply ? 'apply' : 'dry-run'}`);

  for (const item of pending) {
    if (!options.apply) {
      console.log(`DRY ${sourceKey(item)} -> ${pipeline.destination.type}: ${item.title}`);
      continue;
    }

    const created = await createDestinationItem(pipeline.destination, item);
    state.migrations[sourceKey(item)] = {
      createdAt: new Date().toISOString(),
      pipeline: name,
      source: item.source,
      destination: {
        type: pipeline.destination.type,
        id: created.id,
        url: created.url,
      },
      title: item.title,
    };
    saveState(statePath, state);
    markThingsCreated(item, created, pipeline.afterCreate);
    console.log(`CREATED ${sourceKey(item)} -> ${created.url || created.id}`);
  }

  if (!options.apply) {
    console.log('No remote changes made. Re-run with --apply to create destination items.');
  }
}

async function runAllPipelines(config, options) {
  if (options.apply && !options.allowRaw) {
    throw new Error('Raw run-all --apply is disabled. Use prepare/apply-plan per pipeline so issues are curated by the orchestrator first.');
  }
  const entries = Object.entries(config.pipelines || {})
    .filter(([, pipeline]) => !options.group || pipeline.group === options.group);
  if (!entries.length) {
    throw new Error(options.group ? `No pipelines found for group: ${options.group}` : 'No pipelines configured.');
  }

  for (const [name] of entries) {
    await runPipeline(config, name, options);
  }
}

function validateConfig(config) {
  const errors = [];
  if (!config.pipelines || typeof config.pipelines !== 'object') {
    errors.push('Missing pipelines object.');
  }

  for (const [name, pipeline] of Object.entries(config.pipelines || {})) {
    if (!pipeline.source?.type) errors.push(`${name}: missing source.type`);
    if (!pipeline.destination?.type) errors.push(`${name}: missing destination.type`);

    if (pipeline.source?.type === 'notion' && !pipeline.source.dataSourceId) {
      errors.push(`${name}: notion source requires dataSourceId`);
    }

    if (pipeline.destination?.type === 'github' && !pipeline.destination.repo) {
      errors.push(`${name}: github destination requires repo`);
    }
    if (pipeline.destination?.type === 'azure-devops') {
      for (const field of ['organization', 'project']) {
        if (!pipeline.destination[field]) errors.push(`${name}: azure-devops destination requires ${field}`);
      }
    }
    if (pipeline.destination?.type === 'jira') {
      for (const field of ['baseUrl', 'projectKey']) {
        if (!pipeline.destination[field]) errors.push(`${name}: jira destination requires ${field}`);
      }
    }
  }

  if (errors.length) {
    throw new Error(`Invalid config:\n${errors.map((error) => `- ${error}`).join('\n')}`);
  }
  console.log(`Config OK: ${Object.keys(config.pipelines || {}).length} pipeline(s)`);
}

async function main() {
  const args = parseArgs(process.argv.slice(2));
  if (args.help || args._.length === 0) {
    usage();
    return;
  }

  const command = args._[0];
  const { path, config } = loadConfig(args.config);
  if (command === 'list-pipelines') {
    console.log(`Config: ${path}`);
    for (const name of Object.keys(config.pipelines || {})) {
      console.log(name);
    }
    return;
  }

  if (command === 'validate-config') {
    validateConfig(config);
    return;
  }

  if (command === 'prepare') {
    const pipeline = args._[1];
    if (!pipeline) throw new Error('Missing pipeline name.');
    await prepareIssuePlan(config, pipeline, { limit: args.limit, out: args.out });
    return;
  }

  if (command === 'apply-plan') {
    const planPath = args._[1];
    await applyIssuePlan(config, planPath, { apply: Boolean(args.apply) });
    return;
  }

  if (command === 'run') {
    const pipeline = args._[1];
    if (!pipeline) throw new Error('Missing pipeline name.');
    await runPipeline(config, pipeline, { apply: Boolean(args.apply), limit: args.limit, allowRaw: Boolean(args.allowRaw) });
    return;
  }

  if (command === 'run-all') {
    await runAllPipelines(config, { apply: Boolean(args.apply), limit: args.limit, group: args.group, allowRaw: Boolean(args.allowRaw) });
    return;
  }

  throw new Error(`Unknown command: ${command}`);
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
