---
name: agent-readiness
description: Run and interpret the Agent Readiness Framework in tools/agent-readiness, including building the CLI, generating readiness reports, validating JSON output, and using the scripts/readiness.sh wrapper. Use when asked to assess agent readiness, produce readiness reports, validate readiness JSON, or troubleshoot readiness tool output.
---

# Agent Readiness

## Overview
Use the Agent Readiness Framework in `tools/agent-readiness` to generate and validate readiness reports for a repo. Prefer the wrapper script `scripts/readiness.sh` unless direct CLI control is needed.

## Quick start
1. Build the CLI (from `tools/agent-readiness`):
   - `npm install`
   - `npm run build`
2. Generate a report:
   - `node dist/cli.js report --format markdown --out .agent-readiness/latest.json`
3. Validate a report:
   - `node dist/cli.js validate --in .agent-readiness/latest.json`
4. Wrapper alternative:
   - `./scripts/readiness.sh .`

## Workflow
1. Confirm the target repo root and desired output path (default to `.agent-readiness/latest.json`).
2. Generate the report (wrapper or CLI). Capture markdown summary from stdout.
3. Review the JSON report and fix any reported issues if requested.
4. Run validation if the user asks for schema compliance.
5. Reference the JSON schema at `tools/agent-readiness/schemas/readiness-report.schema.json` when needed.

## Reference
For detailed flags, options, and CLI behavior, read `tools/agent-readiness/README.md`.
