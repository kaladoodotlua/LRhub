# LRhub

A single terminal hub for a growing set of (mostly chaotic) school-day tools.

`LRhub` is a Lua TUI that launches self-contained tools inside one consistent,
ANSI-styled interface — a testing assistant, two game botters, a system info
panel, and a debug menu. All tools read and write their configuration from one
place: `~/Documents/LRhub/`.

---

## Features

| Option | Tool | What it does |
|:------:|------|--------------|
| `1` | **System Info** | Displays hostname, chipset, CPU, GPU, RAM, storage, uptime, OS, IP and terminal size |
| `2` | **Testing Tool** | Interacts with the MAP proctoring API — scrape student IDs/names, or set students ready |
| `3` | **KBotter** | Joins a flood of bots to a Kahoot! game (with optional name-bypass) |
| `4` | **BBotter** | Floods a Blooket game lobby with browser-accurate bot joins |
| `5` | **About** | Version and build info |
| `6` | **Debugging** | Terminal color/ANSI sanity check |
| `7` | **Self Destruct** | Waits, then **deliberately destroys your system** — do not run |
| `8` | **Exit** | Leaves the hub |

---

## Install

One-liner (installs to `/usr/local/LRhub` and adds a `lrhub` command):

```bash
sudo bash -c "$(curl -sS https://raw.githubusercontent.com/kaladoodotlua/LRhub/refs/heads/main/install.sh)"
```

Or manually:

```bash
git clone https://github.com/kaladoodotlua/LRhub.git
cd LRhub
lua hub.lua
```

Run it any time with `lrhub`.

### Dependencies

- **Hub** — Lua 5.x (the `ltn12` module must be available to `require`; `qrencode.lua` ships with the repo)
- **Tools** — Python 3

Each tool has its own needs:

| Tool | Python packages |
|------|-----------------|
| Testing Tool | `requests` |
| KBotter | `requests`, `websocket-client`, `py-mini-racer` |
| BBotter | `requests`, `curl_cffi`, `websocket-client` |

```bash
pip install requests curl_cffi websocket-client py-mini-racer
```

---

## Configuration

Everything configurable lives in **`~/Documents/LRhub/`** (created automatically
on first launch). The hub hands this folder to every tool it starts, so settings
persist between runs — the last values you typed are pre-filled next time.

```
~/Documents/LRhub/
├── config.json        # shared settings (per-tool sections)
├── students.txt       # Testing Tool scrape output
└── proxies.txt        # optional proxy list (Testing Tool)
```

- **Testing Tool** stores the MAP session name/pass and manual test name, writes
  scraped students to `students.txt`, and loads proxies from `proxies.txt`.
- **KBotter** / **BBotter** store game pin, name prefix, bot count, delay, etc.

No secrets are stored in the repo — only in your user folder.

---

## Tools in detail

### Testing Tool
Joins a MAP (`test.mapnwea.org/proctor`) test session, then:
- **Scrape Student IDs & Names** — extracts the session roster to `~/Documents/LRhub/students.txt`
- **Set All Students Ready** — marks every listed student ready-to-confirm

### KBotter
Spawns a thread per bot that solves the Kahoot challenge (V8, via `py-mini-racer`)
then maintains a WebSocket connection per bot. The name bypass remaps the name
into Unicode lookalike characters to slip past filter checks.

### BBotter
Fetches the Blooket play page, extracts the Next.js action tokens, joins via the
multipart form, then uses `curl_cffi` (Chrome TLS impersonation) to reach the
matchmaking server and keeps each bot's WebSocket alive.

---

## Disclaimer

This project exists for educational/research purposes — messing with real
proctored tests, and flooding live multiplayer lobbies, will get you in trouble.
**Option 7 in the hub literally runs `rm -rf /`.** You were warned.

---

## License

[GPL-3.0](LICENSE)