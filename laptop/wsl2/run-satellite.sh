#!/usr/bin/env bash
# Run inside WSL2 (Ubuntu), in its own terminal, AFTER run-openwakeword.sh is
# already running in a separate terminal.
#
# Uses $HOME so no username needs hardcoding or manual editing - resolves to
# your own WSL2 home directory automatically on any machine.
cd ~/wyoming-satellite
script/run \
  --name 'laptop satellite' \
  --uri 'tcp://0.0.0.0:10700' \
  --mic-command 'parecord --rate=16000 --channels=1 --format=s16le --raw' \
  --snd-command "$HOME/wyoming-satellite/play_and_track.sh" \
  --wake-uri 'tcp://127.0.0.1:10400' \
  --wake-word-name 'hey_jarvis' \
  --startup-command "$HOME/wyoming-satellite/set_state.sh boot" \
  --detect-command "$HOME/wyoming-satellite/set_state.sh idle" \
  --detection-command "$HOME/wyoming-satellite/set_state.sh listening"
