#!/usr/bin/env bash
# Guards for this public repository: only allowlisted files, the staging plugin
# points only at the verified staging endpoint, and nothing executable ships.
set -euo pipefail
cd "$(dirname "$0")/.."

allowed='^(\.claude-plugin/marketplace\.json|\.github/workflows/validate\.yml|\.gitignore|LICENSE|README\.md|scripts/check\.sh|plugins/closetmatchr-staging/(\.claude-plugin/plugin\.json|\.mcp\.json|LICENSE|README\.md|skills/[a-z-]+/SKILL\.md))$'
bad=$(git ls-files | grep -Ev "$allowed" || true)
[ -z "$bad" ] || { echo "Files outside the allowlist:"; echo "$bad"; exit 1; }

url=$(node -e 'const c=require("./plugins/closetmatchr-staging/.mcp.json").mcpServers; const s=Object.values(c); if (s.length!==1) process.exit(2); console.log(s[0].type+" "+s[0].url+" "+Object.keys(s[0]).sort().join(","))')
[ "$url" = "http https://staging.closetmatchr.com/mcp type,url" ] || { echo "Unexpected MCP config: $url"; exit 1; }

# claude.ai marketplace sync strips plugin.json keys it does not know (it
# stripped privacyPolicyUrl in 0.1.2 although `claude plugin validate --strict`
# accepts it), so only keys the web sync is known to accept may ship.
keys=$(node -e 'console.log(Object.keys(require("./plugins/closetmatchr-staging/.claude-plugin/plugin.json")).sort().join(","))')
[ "$keys" = "author,description,displayName,homepage,keywords,license,name,repository,version" ] || { echo "Unexpected plugin.json keys: $keys"; exit 1; }

for dir in hooks bin agents monitors commands; do
  [ ! -e "plugins/closetmatchr-staging/$dir" ] || { echo "Unexpected component: $dir"; exit 1; }
done

if git grep -nIiE '(api[_-]?key|secret|token|password)["'"'"' ]*[:=] *["'"'"'][A-Za-z0-9_\-]{12,}|Bearer [A-Za-z0-9._\-]{20,}|BEGIN [A-Z ]*PRIVATE KEY' -- . ':!scripts/check.sh'; then
  echo "Possible credential found"; exit 1
fi
echo "content checks passed"
