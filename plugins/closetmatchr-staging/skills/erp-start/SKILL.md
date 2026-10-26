---
name: erp-start
description: Start or orient work in a ClosetMatchR ERP organization through the ClosetMatchR connector. Use when the user mentions ClosetMatchR, their ERP, catalogue, articles or variants and the session has not yet confirmed which organization is connected, or before the first execute call of a session.
---

# Get oriented in a ClosetMatchR ERP organization

This plugin connects to **ClosetMatchR staging** (`https://staging.closetmatchr.com/mcp`). Say so when it matters: staging is a test environment, not the production ERP.

The connector exposes a small fixed toolset: `search`, `read`, `execute`, `analyze` (read-only), `save`, `activate`, plus any tools the organization's own server plugins add (`plugin_*`). The live environment is the source of truth; this skill only tells you where to look. The platform evolves faster than this plugin, so take code shapes and API names from the live docs, not from memory or from this file.

## First steps (read-only)

1. `read` `/AGENTS.md`. Follow its working agreements; it overrides anything here.
2. Learn the execution contract before the first `execute`: `read` `/docs/effect.md` if `/AGENTS.md` points to it. Code there is an **Effect program** (contract `cmr.effect/1`): platform functions return an Effect that you run with `yield*`; there is no `await`, no `async` and no global `erp`. If `/docs/effect.md` does not exist, the deployment is older: use the shape `/docs/api.md` shows.
3. Confirm the organization, role and permissions with `erp.me()` and tell the user which organization is connected. Under the Effect contract the `execute` code is the body of `Effect.gen` with `erp` in scope:

   ```js
   return yield* erp.me()
   ```

   If it is not the organization the user expects, stop: they choose the organization while signing in, so they must disconnect and reconnect the connector.
4. Before writing code or queries, `read` `/docs/api.md` and the relevant `/schemas/*.json`; use `search` for anything else (`/docs`, `/policies`, `/plugins`, `/runs`).
5. For questions about the data (counts, revenue, stock, orders, statuses, trends), use `analyze` and follow the `erp-catalog` skill ("Questions about the data").

A good first request to suggest: *"Read /AGENTS.md, tell me which organization is connected and show 5 articles. Don't change anything."* For that, `erp.articles.find({ limit: 5 })` (run with `yield*`) is enough.

If `execute` or `analyze` fails with `contract_violation`, or with a syntax error about `await`, the code was not an Effect (for example `return await erp.me()` or an `async` function). Reread `/docs/effect.md` and rewrite it with `yield*`; do not retry the same code.

## Rules that always apply

- One organization per connection. Never combine, copy or compare data across organizations, and never ask the user for tokens, cookies or API keys: sign-in is the connector's OAuth flow; credentials for outside systems are entered by the user in the portal.
- Rights come from the user's role and the organization's policies. Effect, plugins and skills grant nothing extra; if something is `forbidden`, report it rather than looking for another route.
- Stay within what the user asked for. Writes through `execute` and `save` take effect immediately and stay if a later step fails; `activate` changes what runs. When the request is clear (which objects, which values), carry it out and report what changed with the run id. Ask first only when something does not follow from the request or context: an unclear selection or value, a change wider than asked, or a business rule such as a new policy (see `/AGENTS.md`).
- Keep reads narrow: always `limit`, filter by id where possible. Unfiltered variant counts or `include: ['variants']` over many articles can be slow.
- Answer in the user's language.

For history and edits, see the `erp-catalog` skill; for server plugins, `erp-plugins`; for imports from external systems, `erp-importer`.

## If the connector is missing or unauthenticated

- Claude Code: run `/mcp`, select `plugin:closetmatchr-staging:closetmatchr-staging` and authenticate.
- Claude apps: Customize › Plugins › ClosetMatchR ERP (staging) › Connectors › Connect.
- Sign in with your own ClosetMatchR account and pick the organization. No API key is needed.
