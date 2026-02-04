#!/bin/bash
set -e

echo -e "\nChecking for required commands...\n"

if command -v git >/dev/null 2>&1; then
    echo -e "\e[32mGit installed!\e[0m"
else
    echo -e "\e[31mGit is not installed. Please install it.\e[0m"
    exit 1
fi

if command -v lua >/dev/null 2>&1; then
    echo -e "\e[32mLua installed!\e[0m"
else
    echo -e "\e[31mLua is not installed. Please install it.\e[0m"
    exit 1
fi

INSTALL_DIR="/usr/local/LRhub"
VERSION=1.3

echo -e "\nCloning LRhub into $INSTALL_DIR..."

if [ -d "$INSTALL_DIR" ]; then
    echo -e "\e[33mExisting LRhub directory found. Removing...\e[0m"
    rm -rf "$INSTALL_DIR"
fi

git clone https://github.com/kaladoodotlua/LRhub.git "$INSTALL_DIR"

echo -e "\nCreating run script..."

sudo tee /usr/bin/lrhub >/dev/null << EOF
#!/bin/bash
cd "$INSTALL_DIR" || exit 1
lua hub.lua "\$@"
EOF

chmod +x "/usr/bin/lrhub"

echo -e "\n\e[32mLRhub installed successfully!\e[0m"
echo -e "Cleaning up...\n"
mv $INSTALL_DIR/LRhub-v$VERSION/tools $INSTALL_DIR
mv $INSTALL_DIR/LRhub-v$VERSION/hub.lua $INSTALL_DIR
rm -r $INSTALL_DIR/LRhub-v$VERSION

echo -e "Run with:\n\e[33mlrhub\e[0m"
