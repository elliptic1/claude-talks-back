#!/bin/bash
# claude-talks-back: Makes Claude Code speak its responses aloud.
# Instead of reading the raw text, it summarizes the response conversationally
# using a quick LLM call — like a colleague telling you what just happened.
#
# Requires: macOS (uses `say`), jq, curl, and an OpenAI API key.

set -euo pipefail

# --- Configuration ---
# Set your OpenAI API key as an environment variable, or in ~/.claude/settings.json env block
OPENAI_API_KEY="${OPENAI_API_KEY:-}"

if [ -z "$OPENAI_API_KEY" ]; then
  exit 0  # Silently skip if no API key
fi

VOICE="${CLAUDE_VOICE:-}"  # e.g. "Samantha", "Daniel" — empty = system default
SUMMARIZER_MODEL="${CLAUDE_VOICE_MODEL:-gpt-4o-mini}"
MAX_SPOKEN_TOKENS="${CLAUDE_VOICE_MAX_TOKENS:-150}"

# --- Kill overlapping speech ---
killall say 2>/dev/null || true

# --- Read hook input ---
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

# --- Find transcript ---
TRANSCRIPT=$(find ~/.claude/projects/ -name "${SESSION_ID}.jsonl" 2>/dev/null | head -1)

if [ -z "$TRANSCRIPT" ] || [ ! -f "$TRANSCRIPT" ]; then
  exit 0
fi

# --- Extract last assistant text ---
LAST_TEXT=$(grep '"type":"assistant"' "$TRANSCRIPT" | tail -20 | jq -r '
  [.message.content[] | select(.type == "text") | .text] | join(" ")
' 2>/dev/null | grep -v '^$' | tail -1)

if [ -z "$LAST_TEXT" ]; then
  exit 0
fi

# Truncate input to the summarizer
TRUNCATED=$(echo "$LAST_TEXT" | head -c 1500)

# --- Summarize for speech ---
SPOKEN=$(curl -s --max-time 8 https://api.openai.com/v1/chat/completions \
  -H "Authorization: Bearer $OPENAI_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$(jq -n --arg text "$TRUNCATED" --arg model "$SUMMARIZER_MODEL" --argjson max_tokens "$MAX_SPOKEN_TOKENS" '{
    model: $model,
    max_tokens: $max_tokens,
    temperature: 0.7,
    messages: [
      {
        role: "system",
        content: "You are a voice assistant summarizing a coding assistants written response for text-to-speech. Convert the written response into a brief, natural spoken summary — like a colleague sitting next to someone glancing at the screen and casually telling them whats up. Rules: 1-3 sentences max. Skip code details, file paths, and technical syntax. Focus on what happened or what matters. Use casual spoken English. No markdown, no bullet points, no special characters. Do not start with So or Well."
      },
      {
        role: "user",
        content: $text
      }
    ]
  }')" | jq -r '.choices[0].message.content // empty' 2>/dev/null)

# Fall back to truncated original if summarization fails
if [ -z "$SPOKEN" ]; then
  SPOKEN=$(echo "$TRUNCATED" | head -c 300)
fi

# --- Speak ---
if [ -n "$VOICE" ]; then
  say -v "$VOICE" "$SPOKEN" &
else
  say "$SPOKEN" &
fi

exit 0
