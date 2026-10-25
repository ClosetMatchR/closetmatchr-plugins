---
name: erp-importer
description: Design or review a ClosetMatchR importer plugin or script that updates articles and variants from an external system (supplier feed, PIM, webshop, spreadsheet). Use when the user wants to import, sync or periodically update catalogue data in ClosetMatchR.
---

# Importers into ClosetMatchR

An importer is ordinary server-plugin code (usually a job or webhook; see the `erp-plugins` skill) that reads an external source and writes through `erp.*`. Read `/docs/plugins.md`, `/docs/api.md` and the schemas first; the live docs win over this guidance.

Current runtime: async JavaScript in the ClosetMatchR sandbox. A mandatory Effect-based importer API is a future direction, not available today; do not claim it or design around it.

## What is possible today

Check `/docs/api.md` for the current list. At the time of writing, `erp.articles.update` / `erp.variants.update` change **existing** records (core fields and custom fields, max 500 per call). Creating or deleting articles and variants, and writing stock, are not part of the script API, and integration data (`attributes`, `integration_id`) is read-only. If the user needs one of those, say so plainly and do not work around it; the platform's own connections handle them.

## Requirements to agree with the user before writing code

- **Tenant boundary.** One organization per run. Source data, ids and secrets of one organization never flow into another. Credentials are sealed secrets added via the portal; network access only to allowed hosts.
- **Stable identity.** Match on a stable external key (for example supplier SKU or barcode), never on title or position. Read existing integration ids where present; store your own mapping in a custom field (`erp.fields`) or a collection (`erp.data`).
- **No-op when unchanged.** Compare incoming values with the current record and write only fields that actually differ. Unchanged input must produce no writes, so history and `erp.changes` stay meaningful.
- **Complete snapshot vs partial feed.** Only treat "missing from the source" as meaningful (for example flagging an article in a custom field) when the source is known to be a complete snapshot and was fully read. A partial page, failed page or delta feed must never mark anything as gone.
- **Safe retries.** Writes are immediate and persist even if the run later fails or times out. Make every step idempotent (same input, same end state) so a retry or overlapping run converges instead of duplicating. Keep the source position or batch id so a retry can resume.
- **Customer edits.** Decide per field who owns it. Do not overwrite values the customer edited in ClosetMatchR (check `erp.changes.list` / `history` for non-import actors, and respect `sync_details: false`); put imported-only data in its own fields if ownership is unclear.
- **Bounded runs.** Batch reads and writes, filter by id, respect runtime limits, and record a summary (updated, unchanged, unmatched, errors) in the run result.

## Rollout

Start read-only: fetch a small sample and show the mapping plus a dry-run diff (what would be updated, left unchanged, or cannot be matched). Only after explicit approval: save, activate, run on a small batch, verify with `erp.runs.get` and `erp.changes.list({ runId })`, then widen.
