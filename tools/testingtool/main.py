import os, json, random
import requests

RST = "\033[0m"
YELLOW, GREEN, RED = "\033[33m", "\033[32m", "\033[31m"
BRIGHT, ITALIC = "\033[1m", "\033[3m"
INFO = f"\033[1;32m!\033[0m"
ERR = f"\033[1;31m!\033[0m"
STAR = f"\033[1;36m*\033[0m"
SEP = "─" * 27

def clear():
    os.system("clear")

def lrhub_dir():
    d = os.environ.get("LRHUB_DIR")
    if d:
        return d
    return os.path.join(os.path.expanduser("~"), "Documents", "LRhub")

LH = os.path.join(lrhub_dir(), "testingtool")
os.makedirs(LH, exist_ok=True)

CONFIG = os.path.join(LH, "config.json")
PROXIES = os.path.join(LH, "proxies.txt")
STUDENTS = os.path.join(LH, "students.txt")

DEFAULTS = {
    "session_name": "",
    "session_pass": "",
    "manual_test_name": ""
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
    return cfg

class MAP():
    def __init__(self, proxy: str = None) -> None:
        self.endpoint = 'test.mapnwea.org/proctor'
        self.proxy = ({
            'http': 'http://%s' % (proxy),
            'https': 'http://%s' % (proxy),
        } if proxy != None else None)

    def joinTestSession(self, sessionName: str, sessionPass: str):
        return requests.post(
            f'https://{self.endpoint}/joinTestSession',
            json={
                'testSessionName': sessionName,
                'testSessionPassword': sessionPass,
            }, proxies=self.proxy,
        )

    def setReadyToConfirm(self, sessionPass: str, assignedTestId: str, assignedTestName: str, studentId: str, authToken: str):
        return requests.post(
            f'https://{self.endpoint}/setStudentReadyToBeConfirmed',
            headers={'Auth-Token': authToken},
            json={
                'studentBid': studentId,
                'testSessionId': assignedTestId,
                'assignedOrChosenTest': {
                    'testKey': sessionPass,
                    'testName': assignedTestName,
                }
            }, proxies=self.proxy,
        )

cfg = load_config()
for k, v in DEFAULTS.items():
    cfg.setdefault(k, v)

proxies = []
if os.path.exists(PROXIES):
    proxies = [p.strip() for p in open(PROXIES, "r").readlines() if p.strip()]

http = MAP(random.choice(proxies) if len(proxies) != 0 else None)

clear()
print(SEP)
sessionName = input(f"{INFO} Session Name [{cfg['session_name']}]: ").strip() or cfg['session_name']
sessionPass = input(f"{INFO} Session Pass [{cfg['session_pass']}]: ").strip() or cfg['session_pass']
cfg['session_name'] = sessionName
cfg['session_pass'] = sessionPass
save_config(cfg)

test = http.joinTestSession(sessionName, sessionPass)

if test.json().get('errorMessage') == 'NOT_AUTHORIZED':
    print(f"{ERR} Invalid Session Name Or Password")
else:
    while True:
        clear()
        print(SEP)
        print(f"╭ {YELLOW}1{RST} {GREEN}Scrape Student IDs & Student Names{RST}")
        print(f"├ {YELLOW}2{RST} {GREEN}Set All Students Ready{RST}")
        print(f"│\n╰──> ", end="")
        x = input()

        if x == '1':
            try:
                req = http.joinTestSession(sessionName, sessionPass)
                print(f"{INFO} Extracting {BRIGHT}\033[1;36m%s{RST} Students" % (len(req.json()['clientTestSessionDo']['studentSessionList'])))
                with open(STUDENTS, 'w') as f:
                    for student in req.json()['clientTestSessionDo']['studentSessionList']:
                        try:
                            f.write(f'{student["studentNumber"]}:{student["studentNameFirst"]}:{student["studentNameLast"]}\n')
                            print(f"{STAR} Extracted (s{BRIGHT}\033[1;36m{student['studentNumber']}{RST}, {student['studentNameFirst']} {student['studentNameLast']})")
                        except KeyError as Key:
                            print(f"{ERR} Cannot Extract Student, JSON Key Not Found %s" % (Key))
                        except Exception:
                            print(f"{ERR} Cannot Extract Student")
            except Exception as E:
                print(f"{ERR} %s" % (E))
            input('\nPress enter to continue')
        elif x == '2':
            while True:
                data = http.joinTestSession(sessionName, sessionPass)
                try:
                    auth = data.headers['Set-Auth-Token']
                    for student in data.json()['clientTestSessionDo']['studentSessionList']:
                        request = http.setReadyToConfirm(
                            sessionPass,
                            data.json()['clientTestSessionDo']['testSessionId'],
                            student.get('assignedTest').get('testName') if student.get('assignedTest').get('testName') != None else cfg['manual_test_name'],
                            student['studentId'],
                            auth
                        )
                        print(f"{INFO} s%s (%s)" % (student['userId'], request.text))
                except Exception as E:
                    if data.headers.get('Set-Auth-Token') == None:
                        print(f"{ERR} Invalid Session")
                        exit()
                    print(f"{ERR} %s" % (E))
        else:
            print(f"{ERR} Please choose a specified number")