---
name: speak
description: Toggle Claude Code voice responses on/off, change voice, or adjust settings
argument-hint: "[on|off|voice <name>|status]"
allowed-tools: Read, Edit, Write, Bash
---

# Voice Response Control

Manage the claude-talks-back voice system that speaks a conversational summary of each response.

## Arguments

- `/speak` or `/speak status` — Show current voice settings
- `/speak on` — Enable voice responses
- `/speak off` — Disable voice responses
- `/speak voice <name>` — Change the macOS voice (e.g. `/speak voice Samantha`)
- `/speak voices` — List available macOS voices
- `/speak test` — Speak a test phrase to verify it works

## How to implement each command

### status (default)
Read `~/.claude/settings.json` and check if the Stop hook for `speak-response.sh` exists. Also check for `CLAUDE_VOICE` env var. Report the current state.

### on
Read `~/.claude/settings.json`. If no Stop hook exists for speak-response.sh, add one:
```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/scripts/speak-response.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
```
Merge with existing settings — don't replace. If the hook already exists, say it's already enabled.

### off
Read `~/.claude/settings.json` and remove the Stop hook entry that references `speak-response.sh`. Keep all other hooks intact. If no hook exists, say it's already disabled.

### voice <name>
Set the `CLAUDE_VOICE` environment variable in `~/.claude/settings.json` under the `env` key:
```json
{ "env": { "CLAUDE_VOICE": "<name>" } }
```
Merge with existing env vars.

### voices
Run: `say -v '?' | head -30` to show available voices.

### test
Run: `say "Claude talks back is working"` to verify audio output.

## Important
- Always read settings.json before writing to preserve existing settings
- The speak-response.sh script must exist at ~/.claude/scripts/speak-response.sh
- OPENAI_API_KEY must be set (in env or settings.json) for summarization to work
