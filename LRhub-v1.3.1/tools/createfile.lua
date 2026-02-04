print("\27[1;33m!\27[0m Note: Using '~/Directory' won't work please use '/home/user/Directory'\n")
io.write("\27[1;32m!\27[0m Destination: ")
local tloc = io.read()

io.write("\27[1;32m!\27[0m Size (in GB): ")
local size_gb = tonumber(io.read())

if not size_gb or not tloc then
    print("\27[1;33m!\27[0m Usage: lua createfile.lua <size_in_GB> <destination_folder>")
    os.exit(1)
end

if size_gb < 1 then
    print("\27[1;31m!\27[0m Size cannot be smaller than 1 GB")
    os.exit(1)
end

os.execute("mkdir -p " .. tloc)

local handle = io.popen("df -B1 --output=avail " .. tloc .. " | tail -1")
local free_bytes = tonumber(handle:read("*a"))
handle:close()

if not free_bytes then
    print("\27[1;31m!\27[0m Could not determine free space on target drive")
    os.exit(1)
end

local bytes_per_gb = 1024 * 1024 * 1024
local target_size = size_gb * bytes_per_gb

if free_bytes < target_size then
    print(string.format("\27[1;31m!\27[0m Not enough free space! Input: %.2f GB, Available: %.2f GB", 
        target_size / bytes_per_gb, free_bytes / bytes_per_gb))
    os.exit(1)
end

local chunk_size = 64 * 1024 * 1024
local chunk = string.rep("0", chunk_size)
local dest_file_path = tloc .. "/" .. size_gb .. "_gb"
local file, err = io.open(dest_file_path, "wb")
if not file then
    print("\27[1;31m!\27[0m File operation failed: " .. err)
    os.exit(1)
end

local written = 0
local start_time = os.clock()

while written < target_size do
    local to_write = math.min(chunk_size, target_size - written)
    file:write(chunk:sub(1, to_write))
    written = written + to_write

    local elapsed = os.clock() - start_time
    local progress_ratio = written / target_size
    local speed = written / math.max(elapsed, 0.001)
    local remaining = target_size - written
    local eta_sec = remaining / speed
    local eta_min = math.floor(eta_sec / 60)
    local eta_s = math.floor(eta_sec % 60)

    local blocks = 20
    local filled = math.floor(progress_ratio * blocks)
    local bar = ""
    for i = 1, blocks do
        if i <= filled then
            bar = bar .. "\27[42m \27[0m"
        else
            bar = bar .. " "
        end
    end

    io.write(string.format(
        "\r\27[1;32m!\27[0m Written: %.2f%% | ETA: %dm %ds | [%s]",
        progress_ratio * 100,
        eta_min,
        eta_s,
        bar
    ))
    io.flush()
end

file:close()
print("\n\27[1;32m!\27[0m File created at " .. dest_file_path)

