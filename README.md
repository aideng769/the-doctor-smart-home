# The Doctor — Local Smart-Home Voice Assistant

A fully local, event-driven smart-home voice assistant, aesthetically inspired by the Doctor from
*Poppy Playtime*. Two machines — a desktop ("the brain") and a laptop ("the thin client") — run
independent services over MQTT/Wyoming/HTTP/RTSP rather than one monolithic process. Nothing in
this project is exposed to the public internet.

This README is the clone-and-rebuild reference for the **desktop + laptop** setup. Remote access
(Tailscale VPN) is a separate module, added in a later push — not covered here yet.

---

## 1. Architecture at a glance

```
DESKTOP (Windows, "the brain")
└── Docker Desktop (WSL2 backend)
    ├── homeassistant :8123
    ├── mosquitto :1883 (MQTT), :9001 (websockets)
    ├── whisper :10300 (Wyoming STT)
    ├── piper :10200 (Wyoming TTS)
    └── frigate :8971 (web UI), :8554/:8555 (RTSP/WebRTC)

LAPTOP (Windows, "the thin client")
├── Native Windows: eye.py (pygame), go2rtc :1984/:8554
└── WSL2 (Ubuntu): openWakeWord :10400, wyoming-satellite :10700
```

Voice: wake word (`hey_jarvis`) → wyoming-satellite → Whisper (STT) → HA Sentence triggers →
Piper (TTS) → played back on the laptop, driving `eye.py`'s animation via a shared state file.

Camera: USB webcam (laptop) → go2rtc (laptop, native) → Frigate's own internal go2rtc (desktop,
Docker) → Frigate (detection/recording) → Home Assistant.

---

## 2. Prerequisites

- **Desktop:** Windows, Docker Desktop (WSL2 backend), Ollama installed natively (not in Docker,
  not covered by the files in this repo yet).
- **Laptop:** Windows, WSL2 with an Ubuntu distro, a USB webcam.
- **Both:** Windows Firewall rules scoped `-Profile Private` — verify `Get-NetConnectionProfile`
  reports `Private` on both machines before relying on any firewall rule.

---

## 3. What goes where

| File / folder | Machine | Purpose |
|---|---|---|
| `desktop/docker-compose.yml` | Desktop | Defines HA, Mosquitto, Whisper, Piper, Frigate containers |
| `desktop/frigate/config/config.yml` | Desktop | Frigate's camera/detection/recording config |
| `desktop/homeassistant/*.yaml` | Desktop | HA's own configuration, automations, secrets |
| `desktop/mosquitto/config/mosquitto.conf` | Desktop | MQTT broker config |
| `laptop/go2rtc.yaml` | Laptop | Native go2rtc — captures the webcam, serves RTSP |
| `laptop/eye.py` | Laptop | Pygame animation, reads the shared satellite-state file |
| `laptop/.wslconfig` | Laptop | WSL2 memory limit |
| `laptop/wsl2/*.sh` | Laptop (inside WSL2) | Wake word + voice satellite launch/state scripts |

---

## 4. Setting up `.env`

Copy `.env.example` → `.env` and fill in your own real values. **Read this section carefully —
not every value in `.env` is actually read automatically by the tool it's for.** Each tool's
substitution support is different, and this repo is explicit about which is which rather than
pretending everything "just works":

| Variable(s) | Automatic, or manual edit? |
|---|---|
| `MQTT_USERNAME`, `MQTT_PASSWORD` | **Automatic.** Docker Compose reads `.env` and passes these into the `frigate` container's environment; Frigate's own `{FRIGATE_MQTT_USERNAME}`/`{FRIGATE_MQTT_PASSWORD}` syntax in `config.yml` resolves them at startup. Nothing to hand-edit. |
| `GO2RTC_USERNAME`, `GO2RTC_PASSWORD`, `CAMERA_DEVICE_NAME` | **Manual edit required.** go2rtc runs as a native Windows binary here, not via Docker Compose — there's no automatic `.env` loading into its process. Set these as real Windows environment variables yourself before starting go2rtc (go2rtc's own `${VAR}` syntax then resolves them), or just hand-edit `laptop/go2rtc.yaml` directly. |
| `CAMERA_NAME` | **Manual edit required, in 5 places.** Not a value substitution — it's a YAML *key* (`streams: your_camera:`, `cameras: your_camera:`) and part of an HA entity ID (`rest_command.frigate_clip_your_camera`) in several files, which `.env` cannot fill in for a key name. Rename every `your_camera` placeholder to your own camera's label (lowercase, no spaces), consistently, in: `laptop/go2rtc.yaml`, `desktop/frigate/config/config.yml` (two spots), `desktop/homeassistant/configuration.yaml`, and `desktop/homeassistant/automations.yaml`. |
| `DESKTOP_LAN_IP`, `LAPTOP_LAN_IP`, `LAN_SUBNET` | **Manual edit required.** Not a documented Frigate/HA substitution field. Flagged with `MANUAL EDIT` comments at each line in `config.yml` and `automations.yaml`. |
| `VOICE_ASSISTANT_ROOT` | **Partially automatic.** Set as a real env var on both sides — Windows (`go2rtc.yaml`, `eye.py`) and separately in WSL2's `~/.bashrc` (the `.sh` scripts) — since Windows env vars aren't visible inside WSL2. If left unset anywhere, falls back to `C:\VoiceAssistant` / `/mnt/c/VoiceAssistant`. |
| `PHONE_NOTIFY_SERVICE` | **Manual edit required** in `automations.yaml` (embedded inside a Jinja template string — HA's `!secret` can't reach inside one). Find your own value via HA's Developer Tools → Actions, search "notify". |
| `NANOLEAF_ENTITY_ID` | **Partially automatic.** Copy this value into `desktop/homeassistant/secrets.yaml`'s `nanoleaf_entity_id:` line — three of the four references in `automations.yaml` use `!secret nanoleaf_entity_id` and resolve from there automatically. One reference (inside a Jinja `state_attr(...)` call) is flagged `MANUAL EDIT` and needs the same value typed in directly, since `!secret` can't resolve inside a template string either. |
| `HA_SECRETS_SOME_PASSWORD` | Present in `secrets.yaml` as a placeholder; not currently referenced by `!secret` anywhere in this repo's `configuration.yaml`/`automations.yaml` — confirm on your own system whether anything still uses it before relying on it. |

Every manual-edit spot is also marked with a `# MANUAL EDIT` comment directly in the file it's in
— `.env` is the reference for *what* to type, the comment in the file is *where*.

---

## 5. Rebuilding from a clone — step order

1. Clone the repo, copy `.env.example` → `.env`, fill in your own values per the table above, and
   make the manual edits it lists.
2. **Docker stack (desktop):** from the `desktop/` folder, `docker compose up -d` — brings up
   Home Assistant, Mosquitto, Whisper, Piper, and Frigate.
3. **Mosquitto user:** create your MQTT user inside the running `mosquitto` container (e.g. via
   `mosquitto_passwd`) — matching the `MQTT_USERNAME`/`MQTT_PASSWORD` you set in `.env`. The
   actual password hash file (`passwd`) is never committed to this repo.
4. **Home Assistant:** complete onboarding, add the MQTT, Wyoming (Whisper/Piper), and Frigate
   integrations. Frigate's own HA integration (`custom_components/frigate/`) is **not** included
   in this repo — download it from the [frigate-hass-integration releases page](https://github.com/blakeblackshear/frigate-hass-integration/releases)
   and extract it to `desktop/homeassistant/custom_components/frigate/` yourself (it's third-party
   code, not something to check into this repo).
5. **go2rtc + camera (laptop):** install the native go2rtc binary, point `laptop/go2rtc.yaml` at
   your actual camera (`ffmpeg -list_devices` to find its name), run it.
6. **Wake word + satellite (laptop, WSL2):** install `wyoming-openwakeword` and
   `wyoming-satellite`. Run `laptop/wsl2/run-openwakeword.sh` in one terminal, then
   `laptop/wsl2/run-satellite.sh` in a second terminal.
7. **eye.py (laptop, native):** run `eye.py` — it reads the shared `satellite-state.txt` file that
   `set_state.sh`/`play_and_track.sh` write to from inside WSL2 (via the `/mnt/c/...` path, so
   both sides of the Windows/WSL2 boundary see the same file).

---

## 6. A note on `play_and_track.sh`

This script (in `laptop/wsl2/`) contains a few lines that look like broken bash syntax at a
glance — for example `kill "(cat"PENDING_IDLE")"` and `echo !>"PENDING_IDLE"`, which don't follow
normal variable-expansion conventions. **It's committed exactly as-is, unmodified, because it's
the confirmed-working version actually running in production** — the voice pipeline's idle →
listening → doing → idle state cycle has been directly observed working correctly end to end. If
you ever go to "clean up" this script's syntax, test thoroughly first — something about how it's
actually invoked here evidently makes it behave correctly despite its appearance.

---

## 7. What's *not* in this repo (yet, or at all)

- **Tailscale VPN / remote access** — fully built and working, documented separately, to be added
  in a later push.
- **Ollama** and the two conversation agents — native install, not yet captured here.
- **Physical shell design, persona/voice cloning, garage door, Music Assistant** — not part of the
  working system this repo captures; separate project phases.
- `custom_components/frigate/` — third-party code, downloaded per step 4 above, not committed.
- Any runtime data: Frigate's recordings/database, HA's `.storage`/database/logs, Whisper/Piper's
  downloaded model files, Mosquitto's `passwd`/data/log folders. All excluded via `.gitignore` —
  they regenerate automatically or are machine-specific state, not configuration.

---

## 8. Status

| Component | Status |
|---|---|
| Voice pipeline (wake word → STT → Sentence triggers → TTS → eye animation) | Working |
| Frigate camera stack (detection, recording, manual clip-save) | Working |
| Nanoleaf voice control (toggle, brightness, scene) | Working |
| Remote access (Tailscale) | Working — repo module added separately |
