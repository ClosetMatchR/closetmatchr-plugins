# ClosetMatchR plugins for Claude

A Claude plugin marketplace published by ClosetMatchR. It is a third-party marketplace: it is not reviewed, verified or endorsed by Anthropic.

| Plugin | Connects to | Status |
| --- | --- | --- |
| `closetmatchr-staging` | `https://staging.closetmatchr.com/mcp` | Staging only. Test environment, not production data. |

A production plugin will be added here once the production ERP connector is live. Until then there is deliberately no plugin that points at production.

## What the plugin contains

- A remote MCP connector (HTTP, OAuth with dynamic client registration) to the ClosetMatchR ERP staging environment. No API keys, no local server, no hooks, no executables.
- Skills that tell Claude how to work in ClosetMatchR:
  - `erp-start`: confirm the connected organization and read `/AGENTS.md` and the execution contract (`/docs/effect.md`) before anything else.
  - `erp-catalog`: articles, variants, history, compare and edits.
  - `erp-plugins`: ClosetMatchR server plugins as Effect programs, including own services via layers: copy, save, diagnostics, activate an exact version, roll back.
  - `erp-importer`: requirements for importers (no-op on unchanged data, complete snapshots, retries, customer edits, tenant boundary).

The skills point Claude at the live documentation the connector serves (`/AGENTS.md`, `/docs`, `/schemas`); that documentation is the source of truth. Code Claude runs in ClosetMatchR (scripts and server plugins) follows the Effect execution contract `cmr.effect/1` described in `/docs/effect.md`; the skills read it from the live environment, so they follow whatever contract the connected environment serves.

## Install in Claude Code

```text
/plugin marketplace add ClosetMatchR/closetmatchr-plugins
/plugin install closetmatchr-staging@closetmatchr
```

On Claude Code 2.1.275 or later this also works in one step:

```text
/plugin install closetmatchr-staging --marketplace ClosetMatchR/closetmatchr-plugins
```

Or from your shell:

```bash
claude plugin marketplace add ClosetMatchR/closetmatchr-plugins
claude plugin install closetmatchr-staging@closetmatchr
```

Then connect: start Claude Code, run `/mcp`, select `plugin:closetmatchr-staging:closetmatchr-staging` and authenticate. Your browser opens; sign in with your own ClosetMatchR account and choose the organization Claude may use.

## Install in the Claude apps (web, desktop)

Plugins require a paid Claude plan.

1. Open **Customize › Plugins**, click **Add** › **Add marketplace** › **Add from a repository**.
2. Enter `ClosetMatchR/closetmatchr-plugins` (or `https://github.com/ClosetMatchR/closetmatchr-plugins`).
3. Install **ClosetMatchR ERP (staging)**.
4. Open the plugin's **Connectors** tab and click **Connect**, then sign in with your ClosetMatchR account and choose the organization.

On Claude Team or Enterprise an owner may need to allow the marketplace or add the connector for the organization first.

## First prompt

```text
Read /AGENTS.md, tell me which organization is connected and show 5 articles. Don't change anything.
```

## Without the plugin (direct connector)

You can also add the connector on its own, without the skills:

- Claude apps: **Customize › Connectors › + Add › Add custom connector**, name `ClosetMatchR (staging)`, URL `https://staging.closetmatchr.com/mcp`, OAuth client: register automatically.
- Claude Code: `claude mcp add --transport http closetmatchr-staging https://staging.closetmatchr.com/mcp`, then `/mcp` to sign in.

## Data and access

Claude talks directly to ClosetMatchR at the URL above. What Claude can read or change is limited to the organization you choose at sign-in and to your role there; changes to your role apply immediately. The plugin itself stores nothing and contains no credentials. Effect and the skills grant no extra rights. The skills tell Claude to stay within what you asked for and to check with you when a value, selection or business rule does not follow from your request. Privacy: [ClosetMatchR privacy policy](https://closetmatchr.com/privacy).

## Versions

The plugin version in `plugins/closetmatchr-staging/.claude-plugin/plugin.json` is the version of this Claude plugin only; it is unrelated to the versions of plugins you build inside ClosetMatchR. Releases are tagged `closetmatchr-staging--v<version>`. Update with `claude plugin marketplace update closetmatchr` followed by `claude plugin update closetmatchr-staging@closetmatchr`, then run `/reload-plugins` or start a new session. In the Claude apps, updates come from the marketplace in **Customize › Plugins**.

## License

MIT, see [LICENSE](LICENSE).
