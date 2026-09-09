os.execute("stty -echo -icanon")
os.execute("clear")
local version = "v1.4.2"
--[[
disable - os.execute("stty -echo -icanon")
enable - os.execute("stty echo icanon")

bold = \27[1m
italic = \27[3m

red = \27[31m
green = \27[32m
yellow = \27[33m
blue = \27[34m
magenta = \27[35m
cyan = \27[36m
white = \27[37m

bright ! prefix = \27[1;32m!\27[0m
bright * prefix = \27[1;36m*\27[0m
number color    = \27[33m
label color     = \27[32m
error color     = \27[1;31m!\27[0m
warning color   = \27[1;33m!\27[0m
reset = \27[0m
]]

local p = (debug.getinfo(1,"S").source:sub(2):match("(.*/)") or "."):gsub("/$", "")

local home = io.popen("echo $HOME"):read("*a"):gsub("\n","")
local lrhub_dir = home .. "/Documents/LRhub"
os.execute("mkdir -p \"" .. lrhub_dir .. "\"")

print("\27[1mLRhub\27[0m\n\27[3m" .. version .. "\27[0m\n\nLoading...")

local logo = [[

        ,gggg,  ,ggggggggggg,                                      
       d8" "8I dP"""88""""""Y8,  ,dPYb,                 ,dPYb,     
       88  ,dP Yb,  88      `8b  IP'`Yb                 IP'`Yb     
    8888888P"   `"  88      ,8P  I8  8I                 I8  8I     
       88           88aaaad8P"   I8  8'                 I8  8'     
       88           88""""Yb,    I8 dPgg,   gg      gg  I8 dP      
  ,aa,_88           88     "8b   I8dP" "8I  I8      8I  I8dP   88gg
 dP" "88P           88      `8i  I8P    I8  I8,    ,8I  I8P    8I  
 Yb,_,d88b,,_       88       Yb,,d8     I8,,d8b,  ,d8b,,d8b,  ,8I  
  "Y8P"  "Y88888    88        Y888P     `Y88P'"Y88P"`Y88P'"Y88P"'  
]]

local hostname = io.popen("hostname"):read("*a"):gsub("\n","")
local chipset = io.popen("lspci | grep -i 'host bridge' | cut -d':' -f3- | sed 's/^ *//'"):read("*a"):gsub("\n","")
local instructionset = io.popen("uname -m"):read("*a"):gsub("\n","")
local cpu = io.popen("lscpu | grep 'Model name' | awk -F: '{print $2}' | sed 's/^ *//'"):read("*a"):gsub("\n","")
local gpu = io.popen("lspci | grep -i 'vga' | cut -d':' -f3- | sed 's/^ *//'"):read("*a"):gsub("\n","")
local osname = io.popen("lsb_release -ds | tr -d '\"'"):read("*a"):gsub("\n","")
local ip = io.popen("hostname -I | awk '{print $1}'"):read("*a"):gsub("\n","")
local termsize = io.popen("stty size 2>/dev/null"):read("*a"):gsub("\n","")
local ram = io.popen("free -h | awk '/Mem:/ {print $2}'"):read("*a"):gsub("\n","")
local storage = io.popen("df -h --output=size / | tail -n1 | sed 's/^ *//'"):read("*a"):gsub("\n","")
local uptimes = io.popen("cat /proc/uptime | awk '{print $1}'"):read("*a"):gsub("\n","")
local s = tonumber(uptimes)
local d = math.floor(s/86400)
local h = math.floor((s%86400)/3600)
local m = math.floor((s%3600)/60)
local uptime = d.."d "..h.."h "..m.."m"

local function banner(title)
	print("\27[1mLRhub\27[0m\n\27[3m" .. version .. "\27[0m\n\n" .. title .. "\n───────────────────────────\n")
end

local function wait_for_enter()
	print("\n───────────────────────────\nPress enter to go back")
	io.write("> ")
	io.read()
end

local function run_tool(name, subdir, cmd)
	cmd = cmd or "python3 -u main.py"
	os.execute("clear")
	banner("Running '" .. name .. "'")
	os.execute("cd \"" .. p .. "/" .. subdir .. "\" && LRHUB_DIR='" .. lrhub_dir .. "' " .. cmd)
	wait_for_enter()
	os.execute("clear")
end

local function version_number(v)
	local a, b, c = v:match("v?(%d+)%.?(%d*)%.?(%d*)")
	return tonumber(a or 0) * 10000 + tonumber(b or 0) * 100 + tonumber(c or 0)
end

local function latest_version()
	local out = io.popen("curl -s --max-time 5 https://raw.githubusercontent.com/kaladoodotlua/LRhub/main/hub.lua | grep -o 'version = \"[^\"]*\"' | head -1 | cut -d'\"' -f2"):read("*a"):gsub("%s", "")
	return out ~= "" and out or nil
end

local function debug_paths()
	os.execute("clear")
	banner("Debugging - Path Info")
	print("\27[33mScript Dir\27[0m - " .. p)
	print("\27[33mConfig Root\27[0m - " .. lrhub_dir)
	print("\27[33mHome\27[0m - " .. home)
	print("\27[33mTerminal Size\27[0m - " .. termsize)
	print("\27[33mTerminal\27[0m - " .. (os.getenv("TERM") or "unknown"))
	wait_for_enter()
end

local function debug_config()
	os.execute("clear")
	banner("Debugging - Data Folder")
	print("\27[33m" .. lrhub_dir .. "\27[0m\n")
	os.execute("find \"" .. lrhub_dir .. "\" -mindepth 1 | sort")
	print("\n───────────────────────────\nUsage:")
	os.execute("du -sh \"" .. lrhub_dir .. "\"")
	wait_for_enter()
end

local function check_python(mod)
	local out = io.popen("python3 -c 'import " .. mod .. "' 2>&1"):read("*a")
	if out == "" or out:match("^%s*$") then
		print("\27[1;32m!\27[0m " .. mod .. " - OK")
	else
		print("\27[1;31m!\27[0m " .. mod .. " - MISSING")
	end
end

local function debug_deps()
	os.execute("clear")
	banner("Debugging - Dependency Check")
	print("\27[33mLua\27[0m")
	local ltn = pcall(require, "ltn12")
	if ltn then print("\27[1;32m!\27[0m ltn12 - OK") else print("\27[1;31m!\27[0m ltn12 - MISSING") end
	print("\n\27[33mTesting Tool\27[0m")
	check_python("requests")
	print("\n\27[33mBBotter\27[0m")
	check_python("requests")
	check_python("curl_cffi")
	check_python("websocket")
	print("\n\27[33mKBotter\27[0m")
	check_python("requests")
	check_python("websocket")
	check_python("py_mini_racer")
	wait_for_enter()
end

local function debug_endpoints()
	os.execute("clear")
	banner("Debugging - Endpoint Check")
	local endpoints = {
		{"MAP Proctor", "https://test.mapnwea.org/proctor"},
		{"Blooket", "https://play.blooket.com"},
		{"Kahoot", "https://kahoot.it"},
	}
	for _, e in ipairs(endpoints) do
		local code = io.popen("curl -s -o /dev/null -w '%{http_code}' --max-time 6 -k '" .. e[2] .. "' 2>/dev/null"):read("*a")
		if tonumber(code) then
			print("\27[1;32m!\27[0m " .. e[1] .. " - reachable (" .. code .. ")")
		else
			print("\27[1;31m!\27[0m " .. e[1] .. " - UNREACHABLE")
		end
	end
	wait_for_enter()
end

local function debug_ansi()
	os.execute("clear")
	banner("Debugging - ANSI Test")
	print("\27[41m  \27[42m  \27[43m  \27[44m  \n\27[45m  \27[46m  \27[47m  \27[100m  \n\27[101m  \27[102m  \27[103m  \27[104m  \n\27[105m  \27[106m  \27[107m  \27[40m  \27[0m")
	wait_for_enter()
end

local function debug_menu()
	while true do
		os.execute("clear")
		banner("Debugging Menu")
		print("╭ \27[33m1\27[32m Path Info - Script and data folder paths\27[0m")
		print("├ \27[33m2\27[32m Data Folder - Lists everything under ~/Documents/LRhub\27[0m")
		print("├ \27[33m3\27[32m Dependency Check - Lua and Python modules\27[0m")
		print("├ \27[33m4\27[32m Endpoint Check - Reachability of tool APIs\27[0m")
		print("├ \27[33m5\27[32m ANSI Test - Color palette sanity check\27[0m")
		print("│ \n├ \27[33mb\27[32m Back - Return to the main menu\27[0m\n│")
		io.write("╰──> ")
		local c = io.read()
		if c == "1" then
			debug_paths()
		elseif c == "2" then
			debug_config()
		elseif c == "3" then
			debug_deps()
		elseif c == "4" then
			debug_endpoints()
		elseif c == "5" then
			debug_ansi()
		elseif c:lower() == "b" then
			break
		else
			print("\27[1;31m!\27[0m Please choose a specified option")
			os.execute("sleep 1")
		end
	end
	os.execute("clear")
end

while true do
	os.execute("clear")
	print(logo)
	print("\27[1mLRhub\27[0m\n\27[3m" .. version .. "\27[0m\n\nSelect an option\n───────────────────────────\n")
	
	print("╭ \27[33m1\27[32m System Info - Returns system info\27[0m")
	print("├ \27[33m2\27[32m Testing Tool - A tool designed to mess with MAP testing\27[0m")
	print("├ \27[33m3\27[32m KBotter - A Kahoot game botter\27[0m")
	print("├ \27[33m4\27[32m BBotter - A Blooket game flooder\27[0m")
	print("├ \27[33m5\27[32m QR Codes - Encode text into a QR code\27[0m")
	print("├ \27[33m6\27[32m About - Returns info about LRHub\27[0m")
	print("├ \27[33m7\27[32m Debugging - Opens a debugging menu\27[0m")
	print("│ \n├ \27[33m8\27[32m Exit - Exits the program\27[0m\n│")
	
	os.execute("stty echo icanon")
	io.write("╰──> ")
	local inp = io.read()
	io.write("\n")
	inp = tonumber(inp)
	
	if inp and inp > 0 and inp < 9 then
		if inp == 1 then
			os.execute("clear")
			banner("System Information")
			print("\27[33mChipset\27[0m - " .. chipset)
			print("\27[33mInstruction Set\27[0m - " .. instructionset)
			print("\27[33mCPU\27[0m - " .. cpu)
			print("\27[33mGPU\27[0m - " .. gpu)
			print("\27[33mHostname\27[0m - " .. hostname)
			print("\27[33mOS\27[0m - " .. osname)
			print("\27[33mIP\27[0m - " .. ip .. " - \27[33mType\27[0m - Private")
			print("\27[33mTerminal Size\27[0m - " .. termsize)
			print("\27[33mRAM\27[0m - " .. ram)
			print("\27[33mStorage\27[0m - " .. storage)
			print("\27[33mUptime\27[0m - " .. uptime)
			wait_for_enter()
		elseif inp == 2 then
			run_tool("Testing tool", "tools/testingtool")
		elseif inp == 3 then
			run_tool("KBotter", "tools/KBotter")
		elseif inp == 4 then
			run_tool("BBotter", "tools/BBotter")
		elseif inp == 5 then
			run_tool("QR Codes", "tools/qrcodes", "lua main.lua")
		elseif inp == 6 then
			os.execute("clear")
			banner("About")
			print("\27[33mVersion\27[0m - " .. version)
			local latest = latest_version()
			if latest then
				print("\27[33mLatest Available\27[0m - " .. latest)
				if version_number(latest) > version_number(version) then
					print("\27[1;33m!\27[0m A newer version is available. Run 'git pull' or reinstall.")
				end
			else
				print("\27[33mLatest Available\27[0m - Unknown (offline)")
			end
			print("\27[33mCreated\27[0m - September 21st, 2025")
			wait_for_enter()
		elseif inp == 7 then
			debug_menu()
		elseif inp == 8 then
			print("Exiting...")
			os.execute("sleep 1")
			os.execute("clear")
			break
		end
	else
		print("\27[1;31m!\27[0m Please choose a specified number")
		os.execute("stty -echo -icanon")
		os.execute("sleep 1")
		os.execute("stty echo icanon")
	end
end