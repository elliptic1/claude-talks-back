#!/bin/bash
# One-line installer for claude-talks-back
# Usage: curl -fsSL https://raw.githubusercontent.com/elliptic1/claude-talks-back/main/install.sh | bash

set -euo pipefail

SCRIPT_DIR="$HOME/.claude/scripts"
SETTINGS_FILE="$HOME/.claude/settings.json"
SCRIPT_URL="https://raw.githubusercontent.com/elliptic1/claude-talks-back/main/speak-response.sh"

echo "Installing claude-talks-back..."

# Check dependencies
if ! command -v jq &>/dev/null; then
  echo "Error: jq is required. Install with: brew install jq"
  exit 1
fi

if ! command -v say &>/dev/null; then
  echo "Error: macOS 'say' command not found. This tool requires macOS."
  exit 1
fi

# Download script
mkdir -p "$SCRIPT_DIR"
curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_DIR/speak-response.sh"
chmod +x "$SCRIPT_DIR/speak-response.sh"

# Add Stop hook to settings.json
if [ -f "$SETTINGS_FILE" ]; then
  # Merge with existing settings
  EXISTING=$(cat "$SETTINGS_FILE")
  HAS_STOP=$(echo "$EXISTING" | jq 'has("hooks") and (.hooks | has("Stop"))' 2>/dev/null)

  if [ "$HAS_STOP" = "true" ]; then
    echo "Warning: You already have a Stop hook in $SETTINGS_FILE"
    echo "Add this manually to your existing Stop hooks array:"
    echo '  { "type": "command", "command": "'$SCRIPT_DIR'/speak-response.sh", "timeout": 10 }'
  else
    echo "$EXISTING" | jq '.hooks.Stop = [{ "hooks": [{ "type": "command", "command": "'"$SCRIPT_DIR"'/speak-response.sh", "timeout": 10 }] }]' > "$SETTINGS_FILE"
    echo "Hook added to $SETTINGS_FILE"
  fi
else
  # Create new settings file
  cat > "$SETTINGS_FILE" << SETTINGS
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "$SCRIPT_DIR/speak-response.sh",
            "timeout": 10
          }
        ]
      }
    ]
  }
}
SETTINGS
  echo "Created $SETTINGS_FILE with hook"
fi

echo ""
echo "Installed! Now set your OpenAI API key:"
echo ""
echo "  Option A: Add to ~/.claude/settings.json:"
echo '    { "env": { "OPENAI_API_KEY": "sk-..." } }'
echo ""
echo "  Option B: Export in your shell profile:"
echo '    export OPENAI_API_KEY="sk-..."'
echo ""
echo "Optional: customize the voice with CLAUDE_VOICE env var (e.g. 'Samantha', 'Daniel')"
echo "  Run 'say -v ?' to see available voices."
echo ""
echo "Claude Code will now speak a conversational summary of every response."
