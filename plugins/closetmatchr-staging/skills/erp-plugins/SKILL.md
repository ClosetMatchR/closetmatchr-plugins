---
name: erp-plugins
description: Build, copy, inspect, activate or roll back ClosetMatchR server plugins (portal pages, extra MCP tools, jobs, webhooks, endpoints) and their version history. Use when the user wants to customise their ClosetMatchR portal or automate something inside ClosetMatchR.
---

# ClosetMatchR server plugins

"Plugin" here means code that runs **inside ClosetMatchR** for one organization. It is unrelated to this Claude plugin and its version: server plugins have their own immutable version numbers per organization.

Read `/docs/plugins.md` (and `/docs/pages.md` for portal pages) before writing anything; they define the current `plugin.json` fields, export contract, permissions, network/secrets rules and runtime limits. Existing plugins are readable under `/plugins/<namespace>/<name>/`, earlier versions under `/plugins/<id>/@<version>/`; `search` with `includeVersions` searches them.

## Workflow

Before any `save`, `copyFrom` or `activate`, and before calling a `plugin_*` tool that may write, confirm the connected organization (`erp.me()`) and get the user's explicit approval for that step. Reading is always fine.

1. **Look first.** `search`/`read` `/plugins` for an existing plugin to reuse or copy. To start from one, `save` with `copyFrom` (for example `cmr/article-page`); built-in platform plugins are read-only and can only be enabled or disabled.
2. **Save.** `save` a full file (`path`, `content`) and/or `config`. Each save creates a new immutable version and returns the version number, check status, diagnostics and the exact activation step. Saving activates nothing. Fix diagnostics and save again; report remaining findings honestly (they do not block activation).
3. **Activate exactly one version** with `activate` (`plugin`, `version`), after the user approves that exact version. State the permissions it will run with; they never exceed those of the user who activates. Rolling back is activating an earlier version; `enabled: false` turns it off.
4. **Verify.** Use `erp.runs.list({ plugin })` / `erp.runs.get(runId)`, open the portal page, or call the new `plugin_*` tool. Note that new tools may only appear after the client reconnects.

## Runtime facts that change design

- Guest code is JavaScript ES modules with `async` functions in a sandbox with limits on memory, CPU, duration and result size; no Node.js APIs. Use `await`.
- Network only to hosts the manifest allows; credentials are sealed secrets that a user stores via the portal, never in code, plugin config or chat.
- Jobs and webhooks run under the plugin's service identity with the activated version pinned.

Do not claim features the live docs do not describe. In particular, an Effect-based plugin API is not available; write plain async JavaScript.
