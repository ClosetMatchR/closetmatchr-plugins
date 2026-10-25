---
name: erp-start
description: Start or orient work in a ClosetMatchR ERP organization through the ClosetMatchR connector. Use when the user mentions ClosetMatchR, their ERP, catalogue, articles or variants and the session has not yet confirmed which organization is connected.
---

# Get oriented in a ClosetMatchR ERP organization

This plugin connects to **ClosetMatchR staging** (`https://staging.closetmatchr.com/mcp`). Say so when it matters: staging is a test environment, not the production ERP.

The connector exposes a small fixed toolset: `search`, `read`, `execute`, `save`, `activate`, plus any tools the organization's own server plugins add (`plugin_*`). The live environment is the source of truth; this skill only tells you where to look.

## First steps (read-only)

1. `read` `/AGENTS.md`. Follow its working agreements; it overrides anything here.
2. `execute` `return await erp.me()` to confirm the organization, role and permissions. Tell the user which organization is connected before doing anything else. If it is not the one they expect, stop: they choose the organization while signing in, so they must disconnect and reconnect the connector.
3. Before writing code or queries, `read` `/docs/api.md` and the relevant `/schemas/*.json`; use `search` for anything else (`/docs`, `/policies`, `/plugins`, `/runs`).

A good first request to suggest: *"Read /AGENTS.md, tell me which organization is connected and show 5 articles. Don't change anything."* For that, `erp.articles.find({ limit: 5 })` is enough.

## Rules that always apply

- One organization per connection. Never combine, copy or compare data across organizations, and never ask the user for tokens, cookies or API keys: sign-in is the connector's OAuth flow.
- Writes through `execute` and `save` take effect immediately and stay if a later step fails; `activate` changes what runs. Before any write, state what will change (entity, count, fields, example before/after) and get an explicit yes. Prefer a small sample first.
- Keep reads narrow: always `limit`, filter by id where possible. Unfiltered variant counts or `include: ['variants']` over many articles can be slow.
- Answer in the user's language.

For history and edits, see the `erp-catalog` skill; for server plugins, `erp-plugins`; for imports from external systems, `erp-importer`.

## If the connector is missing or unauthenticated

- Claude Code: run `/mcp`, select `plugin:closetmatchr-staging:closetmatchr-staging` and authenticate.
- Claude apps: Customize › Plugins › ClosetMatchR ERP (staging) › Connectors › Connect.
- Sign in with your own ClosetMatchR account and pick the organization. No API key is needed.
