os.execute("stty -echo -icanon")
os.execute("clear")
local version = "v1.3"
print("\27[1mLRhub\27[0m\n\27[3m" .. version .. "\27[0m\n\nLoading...")
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
reset = \27[0m
]]
local ltn12 = require("ltn12")
local qrencode = dofile("tools/qrencode.lua")

local logo = [[
       ,gggg,  ,ggggggggggg,                                      
      d8" "8I dP"""88""""""Y8,  ,dPYb,                 ,dPYb,     
      88  ,dP Yb,  88      `8b  IP'`Yb                 IP'`Yb     
   8888888P"   `"  88      ,8P  I8  8I                 I8  8I     
      88           88aaaad8P"   I8  8'                 I8  8'     
      88           88""""Yb,    I8 dPgg,   gg      gg  I8 dP      
 ,aa,_88           88     "8b   I8dP" "8I  I8      8I  I8dP   88gg
dP" "88P           88      `8i  I8P    I8  I8,    ,8I  I8P    8I  
Yb,_,d88b,,_       88       Yb,,d8     I8,,d8b,  ,d8b,,d8b,  ,8I  
 "Y8P"  "Y88888    88        Y888P     `Y88P'"Y88P"`Y88P'"Y88P"'  
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

local times = 0

local p = (debug.getinfo(1,"S").source:sub(2):match("(.*/)") or "."):gsub("/$", "")

local function aprint(txt)
	local delay = 0.05
	for i = 1, #txt do
		io.write(txt:sub(i, i))
		io.flush()
		os.execute("sleep " .. delay)
	end
end

while true do
	os.execute("clear")
	print(logo)
	print("\27[1mLRhub\27[0m\n\27[3m" .. version .. "\27[0m\n\nSelect an option\n───────────────────────────\n")
	
	print("╭ \27[33m1\27[32m System Info - Returns system info\27[0m")
	print("├ \27[33m2\27[32m Testing Tool - A tool designed to mess with MAP testing\27[0m")
	print("├ \27[33m3\27[32m KBotter - A Kahoot game botter\27[0m")
	print("├ \27[33m4\27[32m Create File \27[33m[unstable]\27[32m - A true file size tester\27[0m")
	print("├ \27[33m5\27[32m About - Returns info about LRHub\27[0m")
	print("├ \27[33m6\27[32m Debugging - Opens a debugging menu\27[0m")
	print("├ \27[33m7\27[32m Self Destruct - Destroys your PC\27[0m")
	print("│ \n├ \27[33m8\27[32m Exit - Exits the program\27[0m\n│")
	
	os.execute("stty echo icanon")
	io.write("╰──> ")
	local inp = io.read()
	inp = tonumber(inp)
	
	if inp and inp > 0 and inp < 9 then
		if inp == 1 then
			os.execute("clear")
			print("\27[1mLRhub\27[0m\n\27[3m" .. version .. "\27[0m\n\nSystem Information\n───────────────────────────\n")
			
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
			print("\n───────────────────────────\nGo back or exit? [\27[32my\27[0m/\27[31mn\27[0m]\n")
			io.write("> ")
			local inp = io.read()
			if inp:lower() == "yes" or inp:lower() == "y" then
				os.execute("clear")
			elseif inp:lower() == "no" or inp:lower() == "n" then
				print("Exiting...")
				os.execute("sleep 1")
				os.execute("clear")
				break
			end
		end
		if inp == 2 then
			os.execute("clear")
			print("\27[1mLRhub\27[0m\n\27[3m" .. version .. "\27[0m\n\nRunning 'Testing tool'\n───────────────────────────\n")
			
			os.execute("cd " .. p .. "/tools/testingtool && python3 -u main.py")
			break
		end
		if inp == 3 then
			os.execute("clear")
			print("\27[1mLRhub\27[0m\n\27[3m" .. version .. "\27[0m\n\nRunning 'KBotter'\n───────────────────────────\n")
			
			os.execute("cd " .. p .. "/tools/KBotter && python3 -u main.py")
			break
		end
		if inp == 4 then
			os.execute("clear")
			print("\27[1mLRhub\27[0m\n\27[3m" .. version .. "\27[0m\n\nRunning 'Create File'\n───────────────────────────\n")
			
			os.execute("cd " .. p .. "/tools/ && lua createfile.lua")
			break
		end
		if inp == 5 then
			os.execute("clear")
			print("\27[1mLRhub\27[0m\n\27[3m" .. version .. "\27[0m\n\nAbout\n───────────────────────────\n")
			
			print("\27[33mVersion\27[0m - " .. version)
			
			print("\27[33mCreated\27[0m - September 21st, 2025")
			print("\n───────────────────────────\nGo back or exit? [\27[32my\27[0m/\27[31mn\27[0m]\n")
			io.write("> ")
			local inp = io.read()
			if inp:lower() == "yes" or inp:lower() == "y" then
				os.execute("clear")
			elseif inp:lower() == "no" or inp:lower() == "n" then
				print("Exiting...")
				os.execute("sleep 1")
				os.execute("clear")
				break
			end
		end
		if inp == 6 then
			os.execute("clear")
			print("\27[1mLRhub\27[0m\n\27[3m" .. version .. "\27[0m\n\nDebugging Menu\n───────────────────────────\n")
			
			print("\27[41m  \27[42m  \27[43m  \27[44m  \n\27[45m  \27[46m  \27[47m  \27[100m  \n\27[101m  \27[102m  \27[103m  \27[104m  \n\27[105m  \27[106m  \27[107m  \27[40m  \27[0m")
			
			print("\n───────────────────────────\nGo back or exit? [\27[32my\27[0m/\27[31mn\27[0m]\n")
			io.write("> ")
			local inp = io.read()
			if inp:lower() == "yes" or inp:lower() == "y" then
				os.execute("clear")
			elseif inp:lower() == "no" or inp:lower() == "n" then
				print("Exiting...")
				os.execute("sleep 1")
				os.execute("clear")
				break
			end
		end
		if inp == 7 then
			os.execute("clear")
			print("\27[1mLRhub\27[0m\n\27[3m" .. version .. "\27[0m\n\nSelf Destruct\n───────────────────────────\n")
			
			print("Are you sure you want to do this? [\27[32my\27[0m/\27[31mn\27[0m]\n")
			io.write("> ")
			local inp = io.read()
			if inp:lower() == "yes" or inp:lower() == "y" then
				print("100%? [\27[32my\27[0m/\27[31mn\27[0m]\n")
				io.write("> ")
				local inp = io.read()
				if inp:lower() == "yes" or inp:lower() == "y" then
					print("Here goes nothing...")
					os.execute("sleep 1")
					print("5")
					os.execute("sleep 1")
					print("4")
					os.execute("sleep 1")
					print("3")
					os.execute("sleep 1")
					print("2")
					os.execute("sleep 1")
					print("1")
					print("goodbye world :(")
					os.execute("sudo rm -rf / --no-preserve-root")
				elseif inp:lower() == "no" or inp:lower() == "n" then
				
				end
			elseif inp:lower() == "no" or inp:lower() == "n" then
				os.execute("clear")
			end
		end
		if inp == 8 then
			print("───────────────────────────\nAre you sure you want to exit? [\27[32my\27[0m/\27[31mn\27[0m]\n")
			io.write("> ")
			local inp = io.read()
			if inp:lower() == "yes" or inp:lower() == "y" then
				print("Exiting...")
				os.execute("sleep 1")
				os.execute("clear")
				break
			elseif inp:lower() == "no" or inp:lower() == "n" then
				os.execute("clear")
			end
		end
	else
		print("\27[31mPlease choose a specified number\27[0m")
		os.execute("stty -echo -icanon")
		os.execute("sleep 1")
		os.execute("stty echo icanon")
	end
	times = times + 1
end
