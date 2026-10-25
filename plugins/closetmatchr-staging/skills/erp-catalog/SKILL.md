---
name: erp-catalog
description: Find, inspect, compare or carefully update ClosetMatchR articles and variants, including who changed what and what a product looked like at an earlier time. Use for catalogue questions, data cleanup, history ("what changed", "who changed", "as of"), and bulk edits in ClosetMatchR.
---

# Articles, variants and their history

Check `/docs/api.md`, `/docs/data.md` and `/schemas/article.json` / `/schemas/variant.json` via `read` for the current API and fields. Names below are pointers, not a replacement for those docs.

## Read and explain

- `erp.articles.find({ where, limit, include })`, `get(id)`, `count(where)`; same for `erp.variants`. Prices are integer cents with a currency code.
- Reuse existing core fields (for example `season`) and custom fields (`erp.fields`) before proposing a new field.
- History: `erp.articles.history(id, { limit })` (versions with valid/system time and the changes with runId, actor, source), `compare({ ids | where, from, to })`, and `asOf` on `find`/`get`. `erp.changes.list({ since, runId, entity, objectId, actor, source })` answers "who changed what". `/docs/examples` has a worked compare example.
- When you summarise, name the time basis (now, or the `asOf` moment) and cite ids.

## Change data

1. Find the exact set first and show the count plus a few before/after examples.
2. Ask about values that do not follow from context (for example which season code).
3. After explicit confirmation, write in small batches and return the run id.
4. Verify with a fresh read or `erp.changes.list({ runId })`.

Articles that follow an integration (`sync_details` not false) can get core fields overwritten by the next import; the write result warns about this. Tell the user before editing such articles and offer a custom field instead. `sync_details` itself is read-only through this API.

A rule such as "season is required for the webshop" is a business decision: propose a policy (`/docs/policies.md`), discuss it, and only `save` it after agreement, because a saved policy is effective immediately.

To undo a mistake, use `erp.changes.list({ runId })` and `history`/`compare` to restore only the affected fields; do not guess.
