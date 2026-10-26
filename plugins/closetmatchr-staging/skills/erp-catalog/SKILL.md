---
name: erp-catalog
description: Find, inspect, compare or update ClosetMatchR articles and variants, including who changed what and what a product looked like at an earlier time, and answer read-only questions about the data (counts, orders, stock, statistics). Use for catalogue questions, data cleanup, history ("what changed", "who changed", "as of"), bulk edits and data analysis in ClosetMatchR.
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

## Questions about the data

Counts, totals, statistics and trends are reads: answer them with `analyze`, not `execute`. `analyze` takes the same Effect code, but the platform refuses every write, network call, tool and job, so nothing can change by accident. There is no separate statistics endpoint and no plugin is needed; `read` `/docs/query.md` for the current query shape and limits.

1. **Discover the sources.** `erp.datasets.list()` shows which datasets you may read; `erp.datasets.describe(name)` shows columns, status values and relations. Orders can live in more than one source, for example orders recorded in ClosetMatchR itself (`orders`, `order_lines`, `returns`) and trade documents imported from an external ERP (`trade_documents`, `trade_lines`). An empty `orders` does not mean there was no trade, and a shipment is not an extra order: do not add sources together.
2. **Check freshness.** Imported data is only as recent as its last published import (`trade_publications.published_at`). Compare that moment and the dates actually present with the period the user asks about. If the data covers only part of it, say so and do not present it as the current state of the month.
3. **Check what statuses mean.** Group by the status columns first to see which values occur. A word like "processed", "revenue" or "active" has no fixed column: pick a definition from the real columns and values, name it (with period and time zone), and ask when several are reasonable. A status of `unknown` means the source code has not been confirmed; it is not "done".
4. **Count one level at a time.** Documents (orders, shipments) and lines (order or trade lines) are different counts; say which one you report and never mix them in one number.

```js
// Fictional example: what is there for October, and how fresh is it?
const sources = yield* erp.datasets.list()
const published = yield* erp.query.run({ from: 'trade_publications', select: ['integration_id', 'published_at'] })
const documents = yield* erp.query.run({
  from: 'trade_documents',
  where: { occurred_on: { gte: '2026-10-01', lt: '2026-11-01' } },
  groupBy: ['kind', 'status', 'source_status'],
  select: { kind: 'kind', status: 'status', sourceStatus: 'source_status', documents: { count: '*' } },
})
return { sources: sources.map(d => d.name), published: published.rows, documents: documents.rows }
```

In the answer, state the source, the publication moment, the period the data really covers, the definition used and whether you counted documents or lines.

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
