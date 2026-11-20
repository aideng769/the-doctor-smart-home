import pygame
import os
import sys
import random

# ── Settings ─────────────────────────────────────────────────────────────
FRAME_RATE = 30
FRAMES_ROOT = r"C:\VoiceAssistant\frames"
STATE_FILE = r"C:\VoiceAssistant\satellite-state.txt"


def load_frames(folder, screen_size):
    if not os.path.exists(folder):
        return []
    files = sorted(f for f in os.listdir(folder) if f.endswith(".png"))
    return [
        pygame.transform.scale(
            pygame.image.load(os.path.join(folder, f)).convert(), screen_size
        )
        for f in files
    ]


def read_state():
    # wyoming-satellite (WSL2) writes to this file on every pipeline event.
    # Any read failure just falls back to idle for one frame and self-corrects
    # on the next read ~33ms later — no need to handle it more carefully than that.
    try:
        with open(STATE_FILE, "r") as f:
            return f.read().strip()
    except (FileNotFoundError, PermissionError):
        return "idle"


def main():
    pygame.init()
    info = pygame.display.Info()
    screen_size = (info.current_w, info.current_h)
    screen = pygame.display.set_mode(screen_size, pygame.FULLSCREEN)
    pygame.display.set_caption("Dr. Sawyer")
    clock = pygame.time.Clock()

    frame_sets = {}
    for name in ["boot", "idle", "listening", "doing"]:
        frames = load_frames(os.path.join(FRAMES_ROOT, name), screen_size)
        frame_sets[name] = frames
        print(f"[Eye] Loaded {len(frames)} frames for '{name}'")

    # Boot plays once, unconditionally, before anything reads real state
    for frame in frame_sets.get("boot", []):
        for event in pygame.event.get():
            if event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                pygame.quit()
                sys.exit()
        screen.blit(frame, (0, 0))
        pygame.display.flip()
        clock.tick(FRAME_RATE)

    index = 0
    last_state = "idle"
    random_hold = 0

    while True:
        for event in pygame.event.get():
            if event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                pygame.quit()
                sys.exit()

        real_state = read_state()
        resolved = real_state if real_state in frame_sets else "idle"

        if resolved != last_state:
            index = 0
            random_hold = 0
            last_state = resolved

        frames = frame_sets.get(resolved, [])
        if frames:
            screen.blit(frames[index], (0, 0))
            pygame.display.flip()

            if random_hold > 0:
                random_hold -= 1
            else:
                index += 1
                if index >= len(frames):
                    index = 0
                    # Occasional pause on a random frame so idle doesn't look
                    # like an exact loop on repeat
                    if resolved == "idle" and random.random() < 0.1:
                        index = random.randint(0, len(frames) - 1)
                        random_hold = random.randint(5, 15)

        clock.tick(FRAME_RATE)


if __name__ == "__main__":
    main()
