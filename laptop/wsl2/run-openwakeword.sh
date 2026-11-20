#!/usr/bin/env bash
# Run inside WSL2 (Ubuntu), in its own terminal. Starts the wake-word
# listener that wyoming-satellite (run-satellite.sh, a separate terminal)
# connects to over localhost.
cd ~/wyoming-openwakeword
script/run --uri 'tcp://0.0.0.0:10400' --preload-model 'hey_jarvis'
