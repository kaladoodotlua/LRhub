#!/usr/bin/env python3
import json, os, re, sys, threading, time, uuid
import requests as rq
from curl_cffi import requests as cr
from websocket import create_connection

RST = "\033[0m"
YELLOW, GREEN, RED = "\033[33m", "\033[32m", "\033[31m"
BRIGHT = "\033[1m"
INFO = f"\033[1;32m!\033[0m"
ERR = f"\033[1;31m!\033[0m"
WARN = f"\033[1;33m!\033[0m"
SEP = "─" * 27

CH = '"Chromium";v="134", "Not:A-Brand";v="24", "Google Chrome";v="134"'
UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/134.0.0.0 Safari/537.36"

def lrhub_dir():
    d = os.environ.get("LRHUB_DIR")
    if d:
        return d
    return os.path.join(os.path.expanduser("~"), "Documents", "LRhub")

LH = os.path.join(lrhub_dir(), "bbotter")
os.makedirs(LH, exist_ok=True)

CONFIG = os.path.join(LH, "config.json")

joined = 0
failed = 0
lock = threading.Lock()

DEFAULTS = {
    "game_pin": "",
    "name_prefix": "KDaBot",
    "bot_amount": "10",
    "delay": 0.1
}

def load_config():
    try:
        if os.path.exists(CONFIG):
            return json.load(open(CONFIG, "r"))
    except Exception:
        pass
    return json.loads(json.dumps(DEFAULTS))

def save_config(cfg):
    json.dump(cfg, open(CONFIG, "w"), indent=2)

def get_play_page(pin):
    for _ in range(25):
        s = rq.Session()
        r = s.get(f"https://play.blooket.com/play?id={pin}", headers={
            "User-Agent": UA, "sec-ch-ua": CH, "sec-ch-ua-mobile": "?0",
            "sec-ch-ua-platform": '"macOS"',
            "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8",
            "Accept-Language": "en-US,en;q=0.9",
        }, timeout=15)
        html = r.text
        if 'name="$ACTION_KEY"' in html:
            return s, html
        time.sleep(0.9)
    return None, None


def build_body(key, naction, nf, name, pin):
    b = "----gcb%016x" % int(time.time() * 1e6)
    def add(n, v):
        return f'--{b}\r\nContent-Disposition: form-data; name="{n}"\r\n\r\n{v}\r\n'
    return b, (add("1_$ACTION_REF_1", "") +
               add("1_$ACTION_1:0", json.dumps({"id": naction, "bound": "$@1"})) +
               add("1_$ACTION_1:1", json.dumps([{"status": "UNSET", "message": "", "fieldErrors": {}}])) +
               add("1_$ACTION_KEY", key) +
               add(f"1_{nf}", name) +
               add("1_joinCode", pin) +
               add("0", json.dumps([{"status": "UNSET", "message": "", "fieldErrors": {}}, "$K1"])) +
               f"--{b}--\r\n").encode()


def post_join(s, pin, nextAction, boundary, body):
    for _ in range(25):
        r2 = s.post(f"https://play.blooket.com/play?id={pin}", headers={
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/141.0.0.0 Safari/537.36",
            "sec-ch-ua": CH, "sec-ch-ua-mobile": "?0", "sec-ch-ua-platform": '"macOS"',
            "next-action": nextAction, "Accept": "text/x-component",
            "Content-Type": f"multipart/form-data; boundary={boundary}",
            "Origin": "https://play.blooket.com", "Referer": f"https://play.blooket.com/play?id={pin}",
            "Sec-Fetch-Site": "same-origin", "Sec-Fetch-Mode": "cors", "Sec-Fetch-Dest": "empty",
            "Accept-Language": "en-US,en;q=0.9",
        }, data=body, timeout=15)
        m = re.search(r'1:\{"status":"([A-Z]+)","message":"(https://[^"]+)"', r2.text)
        if m and m.group(1) == "SUCCESS":
            return m.group(2)
        time.sleep(0.9)
    return None


def matchmake(redirect, cookies):
    up = redirect.split("/")
    host, room_key, token = up[2], up[3], up[5]
    url = f"https://{host}/matchmake/joinById/{room_key}"
    for _ in range(12):
        c = cr.Session(impersonate="chrome124")
        r = c.post(url, headers={
            "User-Agent": UA, "Authorization": f"Bearer {token}",
            "Accept": "application/json", "Content-Type": "application/json",
            "Origin": f"https://{host}", "Referer": redirect,
            "sec-ch-ua": CH, "sec-ch-ua-mobile": "?0", "sec-ch-ua-platform": '"macOS"',
            "Cookie": cookies,
        }, data=b"{}", timeout=20)
        if r.status_code == 200 and r.text.startswith("{"):
            jc = r.json()
            if jc.get("sessionId"):
                return jc
        time.sleep(0.9)
    return None


def bot_join(pin, name):
    global joined, failed
    try:
        s, html = get_play_page(pin)
        if not s:
            raise RuntimeError("play page Cloudflare-blocked")
        cookies = "; ".join(f"{k}={v}" for k, v in dict(s.cookies).items())
        actionKey = re.search(r'name="\$ACTION_KEY" value="([^"]*)"',  html).group(1)
        nextAction = re.search(r'name="\$ACTION_1:0" value="\{&quot;id&quot;:&quot;([a-f0-9]{40})', html).group(1)
        nameField = re.search(r'maxLength="15"[^>]*name="([^"]*)"', html).group(1)

        boundary, body = build_body(actionKey, nextAction, nameField, name, pin)
        redirect = post_join(s, pin, nextAction, boundary, body)
        if not redirect:
            raise RuntimeError("join POST never succeeded")

        jc = matchmake(redirect, cookies)
        if not jc:
            raise RuntimeError("matchmake blocked")

        ws_url = f"wss://{jc['publicAddress']}/{jc['processId']}/{jc['roomId']}?sessionId={jc['sessionId']}"
        ws = create_connection(ws_url, header=[
            "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36",
            "Accept-Language: en-US,en;q=0.9",
            "Origin: https://blooket.com",
            'Sec-Ch-Ua: "Not A(Brand";v="8", "Chromium";v="132", "Google Chrome";v="132"',
            "Sec-Ch-Ua-Mobile: ?0",
            'Sec-Ch-Ua-Platform: "macOS"',
            "Sec-Fetch-Dest: document", "Sec-Fetch-Mode: navigate", "Sec-Fetch-Site: same-site",
        ], timeout=15)
        with lock:
            joined += 1
            print(f"{INFO} Bot {name} added ({joined} in game, {failed} failed)")
        while True:
            ws.settimeout(30)
            try:
                ws.recv()
            except Exception:
                break
    except Exception as e:
        with lock:
            failed += 1
            print(f"{ERR} Bot {name} failed: {str(e)[:90]}")


def main():
    global joined, failed
    try:
        cfg = load_config()
        for k, v in DEFAULTS.items():
            cfg.setdefault(k, v)

        pin = input(f"{INFO} Enter Game Pin [{cfg['game_pin']}]: ").strip() or cfg['game_pin']
        prefix = input(f"{INFO} Enter Name Prefix (will number each bot) [{cfg['name_prefix']}]: ").strip() or cfg['name_prefix']
        amount = input(f"{INFO} Enter Bot Amount [{cfg['bot_amount']}]: ").strip() or cfg['bot_amount']
        delay = input(f"{WARN} Delay between joins (seconds) [{cfg['delay']}]: ").strip() or cfg['delay']

        cfg['game_pin'], cfg['name_prefix'], cfg['bot_amount'], cfg['delay'] = pin, prefix, amount, delay
        save_config(cfg)

        print(f"{WARN} Press ENTER to start flooding:")
        input("> ")

        threads = []
        for i in range(1, int(amount) + 1):
            name = f"{prefix}{i}"
            t = threading.Thread(target=bot_join, args=(pin, name), daemon=True)
            t.start()
            threads.append(t)
            time.sleep(float(delay))

        while joined < int(amount):
            time.sleep(0.5)
        print(f"\n{INFO} Successfully added {joined} of {amount} bots.")
        print(f"{WARN} By closing this program the bots will leave the game.")
        while True:
            time.sleep(60)
    except KeyboardInterrupt:
        print(f"\n{ERR} Stopped. {joined} bots in game.")
        sys.exit(0)


if __name__ == "__main__":
    main()