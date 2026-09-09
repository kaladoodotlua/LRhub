# LRhub

A single colorful terminal hub that puts a bunch of handy — and honestly, pretty
chaotic — tools in one place. Pick one from the menu and it runs with the same
style, the same buttons, the same everything.

**Latest version: v1.4.1**

---

## Quick start

```bash
sudo bash -c "$(curl -sS https://raw.githubusercontent.com/kaladoodotlua/LRhub/refs/heads/main/install.sh)"
```

then just type:

```bash
lrhub
```

The hub creates its own little config area at `~/Documents/LRhub/` on first
launch, so everything you type sticks around for next time.

---

## What's inside

| Menu | Tool | What it does |
|:----:|------|--------------|
| `1` | **System Info** | Specs, storage, uptime, IP and more |
| `2` | **Testing Tool** | Works with the MAP proctoring API — scrape student data or set everyone "ready" |
| `3` | **KBotter** | Fills a Kahoot! game with bots (name-bypass included) |
| `4` | **BBotter** | Fills a Blooket lobby with bots |
| `5` | **QR Codes** | Turns any text into a QR code you can read right in your terminal or save as an image |
| `6` | **About** | Version info — and a heads-up if a newer update exists |
| `7` | **Debugging** | A mini toolkit for figuring out what's wrong |
| `8` | **Exit** | Leaves the hub |

---

## Recent changes

**v1.4.1**
- Removed Self Destruct (yes, it's gone — no more surprises)
- New **QR Codes** tool: type any text, get a live QR code, optionally save it as an image
- **About** now checks which version is the newest available and tells you if you should update
- **Debugging** is now a real menu: path info, config dump, dependency checks, API reachability, and the ANSI palette
- Every tool now keeps its own folder in the config area — no more one shared messy file
- All tools share the exact same look and feel as the hub

---

## Install

**Easy way** (puts LRhub in `/usr/local/LRhub` and adds the `lrhub` command):

```bash
sudo bash -c "$(curl -sS https://raw.githubusercontent.com/kaladoodotlua/LRhub/refs/heads/main/install.sh)"
```

**Manual way** (if you like doing things by hand):

```bash
git clone https://github.com/kaladoodotlua/LRhub.git
cd LRhub
lua hub.lua
```

You need Lua for the hub and Python 3 for the tools.

### Under the hood

| Tool | Needs |
|------|-------|
| Hub | Lua 5.x |
| Testing Tool | `requests` |
| KBotter | `requests`, `websocket-client`, `py-mini-racer` |
| BBotter | `requests`, `curl_cffi`, `websocket-client` |

```bash
pip install requests curl_cffi websocket-client py-mini-racer
```

---

## Where your stuff lives

`~/Documents/LRhub/` is the hub's own little world. Each tool gets its own
folder so nothing gets tangled together:

```
~/Documents/LRhub/
├── testingtool/
│   ├── config.json      # session name, pass, manual test name
│   ├── students.txt     # scraped student list
│   └── proxies.txt      # optional proxies (not required)
├── bbotter/
│   └── config.json      # game pin, name prefix, bot count, delay
├── kbotter/
│   └── config.json      # game pin, player name, bot count, bypass
└── qrcode/
    └── qr_*.ppm         # saved QR code images
```

Every time you restart a tool, it remembers the values you typed last — just
press Enter to keep them, or type new ones.

---

## Tools in detail

### Testing Tool
Join a MAP test session, then either:
- **Scrape Student IDs & Names** — exports the roster to `students.txt`
- **Set All Students Ready** — marks everyone in the session as ready-to-confirm

### KBotter
Spawns a thread per bot. Each one solves Kahoot's JavaScript challenge (via
`py-mini-racer`) and holds its own WebSocket open. The name bypass swaps letters
for Unicode lookalikes to dodge halo filters.

### BBotter
Grabs Blooket's play page, extracts the Next.js action tokens, joins through the
multipart form, then reaches the matchmaking server with a Chrome TLS
fingerprint (`curl_cffi`) and keeps every bot's WebSocket alive.

### QR Codes
Enter text, pick an error-correction level, and the code is drawn straight in
your terminal. Say yes to saving and you get a `.ppm` image you can open with any
image viewer. Everything lands in `~/Documents/LRhub/qrcode/`.

---

## Troubleshooting

Something not working? The **Debugging** menu (`7`) has your back:

- **Dependency Check** — tells you exactly which Lua/Python module is missing
- **Endpoint Check** — pings the MAP, Blooket and Kahoot servers to see if they're reachable
- **Config Folder** — dumps every config file so you can spot bad values
- **Path Info** — shows where LRhub thinks everything lives

Most "it doesn't work" moments are one of those three.

---

## A note of caution

These tools interact with real proctored tests and live game lobbies. They're
for poking around and learning — using them against systems you don't control
can get you into real trouble. Don't pull an option you didn't ask for.

---

## License

[GPL-3.0](LICENSE)