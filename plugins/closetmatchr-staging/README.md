# ClosetMatchR ERP (staging)

Connects Claude to the **staging** ClosetMatchR ERP at `https://staging.closetmatchr.com/mcp` and adds skills for working in a ClosetMatchR organization: orientation, catalogue history and edits, ClosetMatchR server plugins, and importers.

Code Claude runs inside ClosetMatchR follows the Effect execution contract (`cmr.effect/1`); the skills read `/AGENTS.md` and `/docs/effect.md` from the live environment before running code.

This is a test environment; it does not connect to production. Sign-in uses OAuth with your own ClosetMatchR account; you choose the organization and Claude gets only your role's rights there. The plugin contains no credentials, local servers, hooks or executables.

Installation and connection steps: see the repository [README](https://github.com/ClosetMatchR/closetmatchr-plugins#readme).

Quick install in Claude Code (2.1.275 or later):

```text
/plugin install closetmatchr-staging --marketplace ClosetMatchR/closetmatchr-plugins
```

Privacy: [ClosetMatchR privacy policy](https://closetmatchr.com/privacy).
