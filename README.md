# claude-talks-back

**Make Claude Code speak its responses out loud.**

Instead of reading raw terminal output, Claude summarizes each response conversationally and speaks it through your Mac's text-to-speech — like a colleague glancing at the screen and telling you what just happened.

https://github.com/user-attachments/assets/demo.mp4

## How it works

1. Claude Code writes a response to your terminal (the full technical detail)
2. A [Stop hook](https://docs.anthropic.com/en/docs/claude-code/hooks) fires and reads the response from the session transcript
3. GPT-4o-mini converts it into a casual 1-3 sentence spoken summary
4. macOS `say` speaks it aloud

You get the best of both worlds: full written detail on screen, conversational audio summary in your ear.

## Install

```bash
curl -fsSL https://raw.githubusercontent.com/elliptic1/claude-talks-back/main/install.sh | bash
```

Then set your OpenAI API key (needed for the summarization step):

```bash
# Option A: In your shell profile
export OPENAI_API_KEY="sk-..."

# Option B: In Claude Code settings
# Add to ~/.claude/settings.json:
{
  "env": { "OPENAI_API_KEY": "sk-..." }
}
```

## Requirements

- **macOS** (uses the built-in `say` command)
- **jq** (`brew install jq`)
- **Claude Code** (the CLI tool from Anthropic)
- **OpenAI API key** (for the conversational summarization)

## Configuration

Set these environment variables to customize:

| Variable | Default | Description |
|----------|---------|-------------|
| `CLAUDE_VOICE` | System default | macOS voice name (e.g. `Samantha`, `Daniel`) |
| `CLAUDE_VOICE_MODEL` | `gpt-4o-mini` | Model for summarization |
| `CLAUDE_VOICE_MAX_TOKENS` | `150` | Max length of spoken summary |

List available voices:
```bash
say -v '?'
```

## How it really works

Claude Code's [hooks system](https://docs.anthropic.com/en/docs/claude-code/hooks) lets you run commands at specific lifecycle events. This project uses the `Stop` hook, which fires after every Claude response.

The hook script:
1. Reads the session transcript from `~/.claude/projects/`
2. Extracts the last assistant message
3. Sends it to GPT-4o-mini with a prompt that says "summarize this like a colleague casually telling someone what happened"
4. Pipes the summary to `say`

It kills any currently-speaking `say` process first, so responses don't pile up.

## Uninstall

Remove the Stop hook from `~/.claude/settings.json` and delete the script:

```bash
rm ~/.claude/scripts/speak-response.sh
```

## The backstory

This started as "that's impossible" during a late-night coding session with Claude Code. The AI said voice output couldn't be done. After some back and forth, we realized the session transcripts are just JSONL files on disk — standard IPC. Five minutes later, Claude was talking back.

Built during development of [TalkTest](https://talktest.live) — an AI-powered platform for spoken exams and voice interviews. If you think AI voice interaction is interesting, check it out.

## License

MIT
