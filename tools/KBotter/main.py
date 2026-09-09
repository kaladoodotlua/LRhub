from json import dumps as jsonDumps, loads as jsonLoads
from websocket import create_connection
from random import randint, choices
from threading import Thread
from time import time, sleep
from requests import get, session
from uuid import uuid4
from os import system
import os, sys

import solve_challange

INFO = f"\033[1;32m!\033[0m"
ERR = f"\033[1;31m!\033[0m"
WARN = f"\033[1;33m!\033[0m"
SEP = "─" * 27

clear = lambda: system('clear')
# enable ANSI on Windows
system('')

def lrhub_dir():
    d = os.environ.get("LRHUB_DIR")
    if d:
        return d
    return os.path.join(os.path.expanduser("~"), "Documents", "LRhub")

LH = os.path.join(lrhub_dir(), "kbotter")
os.makedirs(LH, exist_ok=True)

playerCount = 0
exitVal = False

bypassCharacters = {
    'a': 'ᗩ', 'b': 'ᗷ', 'c': 'ᑕ', 'd': 'ᗪ', 'e': 'E', 'f': 'ᖴ', 'g': 'G', 'h': 'ᕼ', 'i': 'I',
    'j': 'ᒍ', 'k': 'K', 'l': 'ᒪ', 'm': 'ᗰ', 'n': 'ᑎ', 'o': 'O', 'p': 'ᑭ', 'q': 'ᑫ', 'r': 'ᖇ',
    's': 'ᔕ', 't': 'T', 'u': 'ᑌ', 'v': 'ᐯ', 'w': 'ᗯ', 'x': '᙭', 'y': 'Y', 'z': 'ᘔ'
}
chars = ''.join(bypassCharacters.values())

bot_session = session()

def bypassName(playerName):
    bypassedName = ""
    try:
        playerName = playerName.lower()
        for character in playerName:
            try:
                bypassedName = bypassedName + bypassCharacters[character]
            except:
                bypassedName = bypassedName + character
    except:
        return ''.join(choices(chars, k=5))

    return bypassedName

def join_game(gamePin, playerName):
    global playerCount

    try:
        l_data = randint(100, 999)
        o_data = randint(-999, -100)

        generated_uuid = str(uuid4())
        cookies = {
            'generated_uuid': generated_uuid,
            'player': 'active',
        }

        response = bot_session.get(f'https://kahoot.it/reserve/session/{gamePin}/?{time()}', cookies=cookies)
        session_token = response.headers["X-Kahoot-Session-Token"]
        challange_text = response.json()["challenge"]
        wss_connection = solve_challange.solveChallenge(challange_text, session_token)

        ws = create_connection(f"wss://kahoot.it/cometd/{gamePin}/{wss_connection}")
        ws.send(jsonDumps([{"id":"1","version":"1.0","minimumVersion":"1.0","channel":"/meta/handshake","supportedConnectionTypes":["websocket","long-polling","callback-polling"],"advice":{"timeout":60000,"interval":0},"ext":{"ack":True,"timesync":{"tc":str(time()),"l":0,"o":0}}}]))

        clientId = jsonLoads(ws.recv())[0]["clientId"]

        ws.send(jsonDumps([{"id":"2","channel":"/meta/connect","connectionType":"websocket","advice":{"timeout":0},"clientId":clientId,"ext":{"ack":0,"timesync":{"tc":str(time()),"l":l_data,"o":o_data}}}]))
        ws.recv()

        ws.send(jsonDumps([{"id":"3","channel":"/meta/connect","connectionType":"websocket","clientId":clientId,"ext":{"ack":1,"timesync":{"tc":str(time()),"l":l_data,"o":o_data}}}]))

        while True:
            x = jsonDumps([{"id":"4","channel":"/service/controller","data":{"type":"login","gameid":gamePin,"host":"kahoot.it","name":playerName,"content":"{\"device\":{\"userAgent\":\"Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36\",\"screen\":{\"width\":920,\"height\":974}}}"},"clientId":clientId,"ext":{}}])

            ws.send(x)
            findit = ws.recv()

            if '"loginResponse","cid":' in findit:
                print(f'\n{INFO} Bot {playerCount} added.')
                playerCount += 1
                break

        ws.send(jsonDumps([{"id":"5","channel":"/service/controller","data":{"id":16,"type":"message","gameid":gamePin,"host":"kahoot.it","content":"{\"usingNamerator\":false}"},"clientId":clientId,"ext":{}}]))
        ws.send(jsonDumps([{"id":"6","channel":"/meta/connect","connectionType":"websocket","clientId":clientId,"ext":{"ack":2,"timesync":{"tc":str(time()),"l":l_data,"o":o_data}}}]))

        a = 2
        b = 6
        while True:
            a += 1
            b += 1
            ws.send(jsonDumps([{"id":b,"channel":"/meta/connect","connectionType":"websocket","clientId":clientId,"ext":{"ack":a,"timesync":{"tc":str(time()),"l":l_data,"o":o_data}}}]))
            ws.recv()
    except KeyboardInterrupt:
        pass
    except Exception as e:
        print(f"{ERR} {e}")
        pass

def main():
    global exitVal
    global playerCount
    currentPlayerCount = 0

    if exitVal:
        exit(1)

    try:
        print(SEP)
        gamePin = input(f"{INFO} Enter Game Pin: ").strip()

        playerName = input(f"{INFO} Enter Player Name (Note: will add number incrementally after the name): ").strip()

        playerAmount = input(f"{INFO} Enter Player Amount: ").strip() or "10"

        nameBypass = input(f"{INFO} Use name bypass [y/N]: ").strip()
        if 'y' in nameBypass.lower():
            playerName = bypassName(playerName)

        print(f"{WARN} Press ENTER to start bot:")
        input("> ")

        clear()

        for i in range(int(playerAmount)):
            currentPlayerCount += 1
            Thread(target=join_game, args=[gamePin, f"{playerName}{currentPlayerCount}"]).start()
            sleep(0.1)

        while True:
            if playerCount >= int(playerAmount):
                break
            sleep(0.5)

        clear()

        exitVal = True
        if playerCount != 0:
            print(f'\n{INFO} Successfully added {playerCount} of {playerCount} bots.')
        else:
            print(f'\n{ERR} Failed to add bots.\n')

        print(f'{WARN} By closing this program the bots will leave the game.')
        exit(1)
    except KeyboardInterrupt:
        clear()
        exitVal = True
        exit(1)
    except:
        if not exitVal:
            main()

if not exitVal:
    main()