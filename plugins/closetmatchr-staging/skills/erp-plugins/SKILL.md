---
name: erp-plugins
description: Build, copy, inspect, activate or roll back ClosetMatchR server plugins (portal pages, extra MCP tools, jobs, webhooks, endpoints) and their version history. Use when the user wants to customise their ClosetMatchR portal or automate something inside ClosetMatchR.
---

# ClosetMatchR server plugins

"Plugin" here means code that runs **inside ClosetMatchR** for one organization. It is unrelated to this Claude plugin and its version: server plugins have their own immutable version numbers per organization.

Read `/docs/effect.md`, `/docs/plugins.md` (and `/docs/pages.md` for portal pages, `/docs/webhooks.md` for jobs, webhooks and endpoints) before writing anything; they define the current execution contract, `plugin.json` fields, exports, permissions, network/secrets rules and runtime limits. `/docs/examples/plugin.js` is a complete working plugin. Existing plugins are readable under `/plugins/<namespace>/<name>/`, earlier versions under `/plugins/<id>/@<version>/`; `search` with `includeVersions` searches them.

## Execution contract

New plugin versions run under the Effect contract (`cmr.effect/1`). Every export (page `render` and actions, tools, jobs, webhooks, endpoints, checks) is an Effect or a function `(input, ctx) => Effect`. Platform access comes only from services provided during the run:

- `Erp` from `cmr:erp`: the `erp.*` API, each function returning an Effect.
- `Run` from `cmr:erp`: `{ input, context }` of the current run (plugin, actor, source, jobId, ...).
- `ErpError` from `cmr:erp`: the platform error type, with a `code`.

```js
import { Effect } from 'effect'
import { Erp } from 'cmr:erp'

export const tools = {
  lookup: ({ sku }) => Effect.gen(function* () {
    const erp = yield* Erp
    const page = yield* erp.articles.find({ where: { item_number: sku }, limit: 1 })
    return page.items[0] ?? null
  }),
}
```

There is no global `erp` and no `await erp...`; module-level code cannot call the platform. An `async` export or a Promise fails with `contract_violation`. Plain helper functions for pure computation are fine. Import Effect modules from `effect` / `effect/<Module>` (for example `effect/Schema`); never put `effect` in `dependencies`, the platform provides one pinned version.

### Own services (dependency injection)

To share logic between exports, define a service with `Context.Tag` and provide it with `export const layer`. The layer may use `Erp`; the platform builds it on top of its own services for every run of that plugin:

```js
import { Context, Effect, Layer } from 'effect'
import { Erp } from 'cmr:erp'

class Catalogue extends Context.Tag('custom/Catalogue')() {}
export const layer = Layer.effect(Catalogue, Effect.map(Erp, erp => ({
  bySku: sku => Effect.map(erp.articles.find({ where: { item_number: sku }, limit: 1 }), page => page.items[0] ?? null),
})))

export const tools = {
  bySku: ({ sku }) => Effect.gen(function* () {
    return yield* (yield* Catalogue).bySku(sku)
  }),
}
```

A layer adds structure, not access: it runs with the same rights as the export it serves.

### Existing (legacy) versions

Versions saved before the Effect contract keep running unchanged; `/plugins/<id>/versions.json` shows each version's `contract` (`cmr.effect/1` or `legacy/1`). Any new version or copy, including a copy of an old version, must be in Effect form. Convert `async` exports as `/docs/effect.md` ("Bestaande code") describes: `await erp.x()` becomes `yield* erp.x()` inside `Effect.gen` with `const erp = yield* Erp`, `Promise.all(items.map(async ...))` becomes `Effect.forEach`, `try/catch` becomes `Effect.catchTag('ErpError', ...)`. If the live environment has no `/docs/effect.md`, it predates the contract: follow `/docs/plugins.md` as served.

## Workflow

Confirm the connected organization (`erp.me()`) before the first change. Reading is always fine.

1. **Look first.** `search`/`read` `/plugins` for an existing plugin to reuse or copy. To start from one, `save` with `copyFrom` (for example `cmr/article-page`); built-in platform plugins are read-only and can only be enabled or disabled.
2. **Save.** `save` a full file (`path`, `content`) and/or `config`. Each save creates a new immutable version and returns the version number, check status, diagnostics and the exact activation step. Saving activates nothing. Checks include the export contract (each declared export is called with sample input and must return an Effect). Fix diagnostics and save again; report remaining findings honestly (they do not block activation).
3. **Activate exactly one version** with `activate` (`plugin`, `version`) when the user asked for the plugin to be live. Tell them which version and which permissions it runs with: user actions (pages, tools) use the user's rights; jobs, webhooks and endpoints use the plugin's service identity, limited to the declared `permissions` and never more than the activating user has. Declare only the permissions, hosts and secrets the task needs. Rolling back is activating an earlier version; `enabled: false` turns it off. If activating would replace or disable something the user did not mention, check with them first.
4. **Verify.** Use `erp.runs.list({ plugin })` / `erp.runs.get(runId)`, open the portal page, or call the new `plugin_*` tool. New tools may only appear after the client reconnects.

## Runtime facts that change design

- Sandboxed JavaScript ES modules with limits on memory, CPU, duration, platform calls and result size; no Node.js APIs or timers. Waiting and retries go through Effect (`Effect.sleep`, `Effect.timeout`, `Effect.retry` with `Schedule`) and count toward run duration. See `/docs/runtime.md` for current limits.
- Writes are immediate and stay if the run later fails, times out or is interrupted; design steps to be idempotent. Cleanup with `Effect.acquireRelease` / `Effect.addFinalizer` runs on success, failure and interruption, but only briefly after a stop, so make it repeatable.
- Network only to hosts the manifest allows; credentials are sealed secrets that a user stores via the portal, never in code, plugin config or chat.
- Jobs and webhooks run under the plugin's service identity with the activated version pinned.

Do not claim features the live docs do not describe.
