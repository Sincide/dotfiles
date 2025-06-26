#!/usr/bin/env fish

# Evil Launcher - Fish Shell Wrapper
# Provides easy access to the evil-launcher from anywhere
# Usage: evil-launcher [launch|wall]

set -l launcher_dir "$HOME/dotfiles/app-dev/evil-launcher"
set -l launcher_binary "$launcher_dir/launcher"

# Check if launcher binary exists
if not test -f $launcher_binary
    echo "🔨 Building evil-launcher..."
    cd $launcher_dir
    if not go build -o launcher .
        echo "❌ Failed to build evil-launcher"
        exit 1
    end
    echo "✅ Evil-launcher built successfully"
end

# Change to launcher directory and run
cd $launcher_dir

# Pass all arguments to the launcher
exec ./launcher $argv 