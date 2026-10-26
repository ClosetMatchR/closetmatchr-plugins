---
name: erp-importer
description: Design or review a ClosetMatchR importer plugin or script that updates articles and variants from an external system (supplier feed, PIM, webshop, spreadsheet). Use when the user wants to import, sync or periodically update catalogue data in ClosetMatchR.
---

# Importers into ClosetMatchR

An importer is ordinary server-plugin code (usually a job or webhook; see the `erp-plugins` skill) or an `execute` script that reads an external source and writes through `erp.*`. Read `/AGENTS.md`, `/docs/effect.md`, `/docs/plugins.md`, `/docs/api.md` and the schemas first, and `search` `/docs` for import guidance; the live docs win over this guidance.

## Execution contract

Importer code is an Effect program (contract `cmr.effect/1`, see `/docs/effect.md`): get the API with `const erp = yield* Erp` (in `execute`, `erp` is already in scope), run every call with `yield*`, fetch with `erp.http.fetch`, iterate with `Effect.forEach(..., { concurrency })`, and handle failures with `Effect.catchTag('ErpError', ...)` or your own `Data.TaggedError`. Retries and timeouts use `Effect.retry` / `Effect.timeout` with `Schedule`. A useful structure is a small source service (a `Context.Tag` provided through `export const layer`) that wraps fetching and parsing, so jobs, webhooks and tools share it. If the live environment has no `/docs/effect.md`, follow the shape `/docs/api.md` shows instead.

```js
// plugin.json declares the job, network.allow for the supplier host and the secret name.
import { Effect } from 'effect'
import { Erp } from 'cmr:erp'

export const jobs = {
  importFeed: () => Effect.gen(function* () {
    const erp = yield* Erp
    const response = yield* erp.http.fetch({ url: 'https://supplier.example/feed.json', secret: { name: 'supplier-api', header: 'authorization', format: 'Bearer {secret}' } })
    // map response.json to { id, set } updates with only changed fields, then:
    // yield* erp.articles.update(updates)  (max 500 per call)
    return { received: response.json?.items?.length ?? 0 }
  }),
}
```

## What is possible

Check `/docs/api.md` for the current list. At the time of writing, `erp.articles.update` / `erp.variants.update` change **existing** records (core fields and custom fields, max 500 per call). Creating or deleting articles and variants, and writing stock, are not part of the script API, and integration data (`attributes`, `integration_id`) is read-only. If the user needs one of those, say so plainly and do not work around it; the platform's own connections handle them.

## Requirements to settle before writing code

Settle these from the user's request and the source; ask only where they do not follow from it.

- **Tenant boundary.** One organization per run. Source data, ids and secrets of one organization never flow into another. Credentials are sealed secrets the user adds via the portal; network access only to allowed hosts.
- **Stable identity.** Match on a stable external key (for example supplier SKU or barcode), never on title or position. Read existing integration ids where present; store your own mapping in a custom field (`erp.fields`) or a collection (`erp.data`).
- **No-op when unchanged.** Compare incoming values with the current record and write only fields that actually differ. Unchanged input must produce no writes, so history and `erp.changes` stay meaningful.
- **Complete snapshot vs partial feed.** Only treat "missing from the source" as meaningful (for example flagging an article in a custom field) when the source is known to be a complete snapshot and was fully read. A partial page, failed page or delta feed must never mark anything as gone.
- **Safe retries.** Writes are immediate and persist even if the run later fails, times out or is interrupted. Make every step idempotent (same input, same end state) so a retry or overlapping run converges instead of duplicating. Keep the source position or batch id so a retry can resume.
- **Customer edits.** Decide per field who owns it. Do not overwrite values the customer edited in ClosetMatchR (check `erp.changes.list` / `history` for non-import actors, and respect `sync_details: false`); put imported-only data in its own fields if ownership is unclear.
- **Bounded runs.** Batch reads and writes, filter by id, respect runtime limits (`/docs/runtime.md`), and return a summary (updated, unchanged, unmatched, errors) as the run result.

## Rollout

Start read-only: fetch a small sample and show the mapping plus a dry-run diff (what would be updated, left unchanged, or cannot be matched). This is where unclear mappings surface; resolve them with the user. Then save, activate, run on a small batch, verify with `erp.runs.get` and `erp.changes.list({ runId })`, and widen. To check imported data afterwards (counts per kind or status, what period it covers), use `analyze`, which cannot write; see the `erp-catalog` skill.
