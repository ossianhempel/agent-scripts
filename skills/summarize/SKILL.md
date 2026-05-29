---
name: summarize
description: Summarize and extract content from URLs, articles, PDFs, local files, YouTube videos, videos, podcasts, transcripts, and clipboard/stdin text using the summarize CLI. Use this skill whenever the user asks what a link/video/article/PDF is about, asks for a summary or transcript, wants markdown extraction, or explicitly mentions summarize.sh.
homepage: https://summarize.sh
metadata:
  openclaw:
    emoji: "🧾"
    requires:
      bins:
        - summarize
    install:
      - id: brew
        kind: brew
        formula: steipete/tap/summarize
        bins:
          - summarize
        label: Install summarize via Homebrew
---

# Summarize

Use `summarize` for fast summaries, extraction, and transcripts from web pages,
YouTube/videos, audio/podcasts, PDFs, local files, and stdin/clipboard text.

## First step

Verify the CLI exists:

```bash
summarize --version
```

If it is missing, install it:

```bash
brew install steipete/tap/summarize
```

## Common commands

```bash
summarize "https://example.com"
summarize "/path/to/file.pdf"
summarize "https://youtu.be/..." --youtube auto
pbpaste | summarize -
```

## Extraction and transcripts

Use `--extract` when the user asks for raw content, markdown extraction, or a
transcript instead of a model-written summary:

```bash
summarize "https://example.com" --extract --format md
summarize "https://youtu.be/..." --youtube auto --extract --format md
```

If the extracted output is huge, give a tight summary first and ask what section
or time range to expand.

## Useful flags

- `--length short|medium|long|xl|xxl|<chars>` controls summary length.
- `--max-output-tokens <count>` caps model output.
- `--json` emits machine-readable output with metrics.
- `--plain` disables rich terminal rendering.
- `--firecrawl auto|off|always` controls blocked-site fallback.
- `--youtube auto|web|yt-dlp|apify` controls transcript source.
- `--slides` extracts and includes video slides when supported.
- `--cli <provider>` uses a CLI provider such as `claude`, `codex`,
  `gemini`, `openclaw`, or `copilot`.

## Models and keys

Default model is `auto`; config may choose the provider/model.

Common env vars:

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `GEMINI_API_KEY`
- `XAI_API_KEY`
- `OPENROUTER_API_KEY`
- `GITHUB_TOKEN`

Optional config file:

```json
{ "model": "openai/gpt-5.4" }
```

Save it at `~/.summarize/config.json` when a persistent default is useful.
