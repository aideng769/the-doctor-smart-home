#!/bin/bash
VOICE_ASSISTANT_ROOT="${VOICE_ASSISTANT_ROOT:-/mnt/c/VoiceAssistant}"
echo "$1" > "$VOICE_ASSISTANT_ROOT/satellite-state.txt"
