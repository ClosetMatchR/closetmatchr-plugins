---
name: erp-catalog
description: Find, inspect, compare or update ClosetMatchR articles and variants, including who changed what and what a product looked like at an earlier time. Use for catalogue questions, data cleanup, history ("what changed", "who changed", "as of"), and bulk edits in ClosetMatchR.
---

# Articles, variants and their history

`read` `/docs/api.md`, `/docs/data.md` and `/schemas/article.json` / `/schemas/variant.json` for the current API and fields, and `/docs/effect.md` for how code runs. Names below are pointers, not a replacement for those docs.

## How code runs

Under the Effect contract (`cmr.effect/1`, described in `/docs/effect.md`) every `erp.*` function returns an Effect. In `execute` the code is the body of `Effect.gen` with `erp` in scope, so each call is `yield* erp...`; there is no `await` or global `erp`. Loop over lists with `Effect.forEach`, not `.map(async ...)`. Platform errors are `ErpError` with a `code` (`forbidden`, `not_found`, `invalid_input`, ...); catch them with `Effect.catchTag('ErpError', ...)`. If the live environment has no `/docs/effect.md`, follow the shape `/docs/api.md` shows instead.

```js
const page = yield* erp.articles.find({ where: { brand: 'Example', season: null }, limit: 20 })
return { count: page.items.length, hasMore: page.hasMore, sample: page.items.slice(0, 5).map(a => ({ id: a.id, title: a.title })) }
```

## Read and explain

- `erp.articles.find({ where, limit, include })`, `get(id)`, `count(where)`; same for `erp.variants`. Prices are integer cents with a currency code.
- Reuse existing core fields (for example `season`) and custom fields (`erp.fields`) before proposing a new field.
- History: `erp.articles.history(id, { limit })` (versions with valid/system time and the changes with runId, actor, source), `compare({ ids | where, from, to })`, and `asOf` on `find`/`get`. `erp.changes.list({ since, runId, entity, objectId, actor, source })` answers "who changed what". `/docs/examples` has worked examples.
- When you summarise, name the time basis (now, or the `asOf` moment) and cite ids.

## Change data

1. Find the exact set first so you know the count and can show a few before/after examples.
2. If a value or the selection does not follow from the request or context (for example which season code, or whether "all jackets" includes coats), ask. When the user has already said what to change and on which objects, go ahead.
3. Write in batches (`update` takes up to 500 per call, one transaction each) and keep the run id.
4. Verify with a fresh read or `erp.changes.list({ runId })`, then report what changed and the run id.

```js
const selection = yield* erp.articles.find({ where: { brand: 'Example', season: null }, limit: 500 })
const result = yield* erp.articles.update(selection.items.map(a => ({ id: a.id, set: { season: 'FW26' } })))
return { updated: result.updated.length, runId: result.runId, warnings: result.warnings, findings: result.findings }
```

Articles that follow an integration (`sync_details` not false) can get core fields overwritten by the next import; the write result warns about this. Mention it, and when the user wants the value to stick, offer a custom field instead. `sync_details` itself is read-only through this API.

A rule such as "season is required for the webshop" is a business decision, not part of a data edit: propose a policy (`/docs/policies.md`), discuss it, and only `save` it once the user wants it, because a saved policy is effective immediately.

To undo a mistake, use `erp.changes.list({ runId })` and `history`/`compare` to restore only the affected fields; do not guess. There is no automatic rollback: writes made before a failure stay.
