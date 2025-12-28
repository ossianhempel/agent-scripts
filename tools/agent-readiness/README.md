# Agent Readiness Framework

Deterministic readiness evaluator with a CLI + JSON report schema.

## Usage

Build the CLI:

```sh
npm install
npm run build
```

Run a report:

```sh
node dist/cli.js report --format markdown --out .agent-readiness/latest.json
```

Validate a report:

```sh
node dist/cli.js validate --in .agent-readiness/latest.json
```

Use the repo wrapper script:

```sh
./scripts/readiness.sh .
```

## Tests

```sh
npm run test
```

## Output

- Markdown summary to stdout
- JSON report written to the `--out` path

Schema: `schemas/readiness-report.schema.json`
