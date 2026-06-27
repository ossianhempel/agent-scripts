#!/usr/bin/env node
import { readFileSync } from "node:fs";
import { basename } from "node:path";

export function parseContentMachinePost(markdown) {
  const title = parseTitle(markdown);
  const caption = parseCaption(markdown);
  const onVideoText = parseOnVideoText(markdown);

  if (!title) {
    throw new Error("post.md is missing a top-level title");
  }
  if (!caption) {
    throw new Error("post.md is missing a caption fenced block");
  }

  return { title, caption, onVideoText };
}

function parseTitle(markdown) {
  const match = markdown.match(/^#\s+(.+?)\s*$/m);
  return match?.[1]?.trim() ?? "";
}

function parseCaption(markdown) {
  const match = markdown.match(/^##\s+Caption\s*$[\s\S]*?^```\s*$\n?([\s\S]*?)\n?^```\s*$/m);
  return match?.[1]?.trim() ?? "";
}

function parseOnVideoText(markdown) {
  const items = [];
  const textSection = markdown.match(/^##\s+On-video text\s*$([\s\S]*)/m)?.[1] ?? "";
  const blockPattern = /^###\s+(.+?)\s*$[\s\S]*?^```\s*$\n?([\s\S]*?)\n?^```\s*$/gm;

  for (const match of textSection.matchAll(blockPattern)) {
    const label = match[1]?.trim();
    const text = match[2]?.trim();
    if (label && text) items.push({ label, text });
  }

  return items;
}

function main(argv) {
  const postPath = argv[2];
  if (!postPath) {
    throw new Error(`Usage: ${basename(argv[1] ?? "parse-content-machine-post.mjs")} <post.md>`);
  }

  const parsed = parseContentMachinePost(readFileSync(postPath, "utf8"));
  process.stdout.write(`${JSON.stringify(parsed, null, 2)}\n`);
}

if (import.meta.url === `file://${process.argv[1]}`) {
  try {
    main(process.argv);
  } catch (error) {
    process.stderr.write(`${error instanceof Error ? error.message : String(error)}\n`);
    process.exit(1);
  }
}
