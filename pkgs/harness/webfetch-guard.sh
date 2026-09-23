cat >/dev/null
jq -n --arg reason "WebFetch is disabled in this environment. Fetch pages with the reader CLI instead: reader -o <url> for markdown, reader --raw <url> for plain text, or the reader_fetch MCP tool." '{hookSpecificOutput:{hookEventName:"PreToolUse",permissionDecision:"deny",permissionDecisionReason:$reason}}'
