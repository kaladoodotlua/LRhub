os.execute("clear")

INFO = "\27[1;32m!\27[0m"
ERR = "\27[1;31m!\27[0m"
WARN = "\27[1;33m!\27[0m"
SEP = "───────────────────────────"

local p = (debug.getinfo(1,"S").source:sub(2):match("(.*/)") or "."):gsub("/$", "")
local qr = dofile(p .. "/../qrencode.lua")

local home = os.getenv("HOME") or ""
local lrhub_dir = os.getenv("LRHUB_DIR") or (home .. "/Documents/LRhub")
local save_dir = lrhub_dir .. "/qrcode"
os.execute("mkdir -p \"" .. save_dir .. "\"")

local function render_matrix(tab)
	for y = 1, #tab do
		local line = ""
		for x = 1, #tab do
			local cell = tab[x] and tab[x][y] or 0
			line = line .. (cell > 0 and "██" or "  ")
		end
		print(line)
	end
end

local function qr_to_ppm(tab, path, scale)
	scale = scale or 8
	local size = #tab
	local dim = (size + 8) * scale
	local f = io.open(path, "wb")
	if not f then return false end
	f:write("P6\n" .. dim .. " " .. dim .. "\n255\n")
	local black = string.char(0, 0, 0)
	local white = string.char(255, 255, 255)
	for y = 1, dim do
		local row = math.floor((y - 1) / scale) - 3
		for x = 1, dim do
			local col = math.floor((x - 1) / scale) - 3
			local dark = false
			if row >= 1 and row <= size and col >= 1 and col <= size then
				local cell = tab[col] and tab[col][row] or 0
				dark = cell > 0
			end
			f:write(dark and black or white)
		end
	end
	f:close()
	return true
end

print("\27[1mQR Codes\27[0m\n\27[3mEncode text into a QR code\27[0m")

while true do
	print("\n" .. SEP)
	print(INFO .. " What should the QR encode?")
	io.write("> ")
	local text = io.read()
	if text then text = text:gsub("%s+$", "") end
	if not text or text == "" then
		print(ERR .. " Nothing to encode")
	else
		print(INFO .. " Error correction level (1=Low, 2=Medium, 3=Quartile, 4=High) [2]")
		io.write("> ")
		local ec = tonumber((io.read() or ""):match("%d+")) or 2
		if ec < 1 then ec = 1 elseif ec > 4 then ec = 4 end

		local ok, tab = qr.qrcode(text, ec)
		if not ok then
			print(ERR .. " Failed to generate QR: " .. tostring(tab))
		else
			print("\n" .. SEP)
			render_matrix(tab)
			print(SEP)
			print("\nSave as image? [y/N]")
			io.write("> ")
			local sv = (io.read() or ""):lower()
			if sv:match("^y") then
				local path = save_dir .. "/qr_" .. os.time() .. ".ppm"
				if qr_to_ppm(tab, path) then
					print(INFO .. " Saved to " .. path)
				else
					print(ERR .. " Could not save image")
				end
			end
		end
	end

	print("\n" .. WARN .. " Encode another? [y/N]")
	io.write("> ")
	local again = (io.read() or ""):lower()
	if not again:match("^y") then
		break
	end
	os.execute("clear")
end
os.execute("clear")