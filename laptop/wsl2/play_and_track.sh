#!/bin/bash
VOICE_ASSISTANT_ROOT="${VOICE_ASSISTANT_ROOT:-/mnt/c/VoiceAssistant}"
STATE_FILE="$VOICE_ASSISTANT_ROOT/satellite-state.txt"
PENDING_IDLE=/tmp/pending-idle.pid

# Cancel any pending "return to idle" timer left by the previous chunk
if [ -f "$PENDING_IDLE" ]; then
    kill "(cat"PENDING_IDLE")" 2>/dev/null
    rm -f "$PENDING_IDLE"
fi

echo "doing" > "STATEFILE"
paplay --rate=22050 --channels=1 --format=s16le --raw

# Don't go idle immediately — wait a beat in case another chunk is coming.
# If nothing cancels this within 1s, the response really is finished.
( sleep 1 && echo "idle" > "STATEFILE" ) &
echo !>"PENDING_IDLE"
