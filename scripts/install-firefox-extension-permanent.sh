#!/bin/bash

# Firefox AI Extension - Permanent Installation Helper
# Multiple options for making the extension permanent

EXTENSION_XPI="$(pwd)/firefox-ai-extension.xpi"
FIREFOX_DEV_URL="https://www.mozilla.org/en-US/firefox/developer/"

echo "🔥 Firefox AI Extension - Permanent Installation"
echo "================================================"
echo ""

# Check if .xpi file exists
if [[ ! -f "$EXTENSION_XPI" ]]; then
    echo "❌ Extension package not found: $EXTENSION_XPI"
    echo "🔧 Creating .xpi package..."
    cd firefox-ai-extension && zip -r ../firefox-ai-extension.xpi . -x "*.log" "*.tmp" ".DS_Store"
    cd ..
fi

echo "📦 Extension package ready: $EXTENSION_XPI"
echo ""

echo "🎯 PERMANENT INSTALLATION OPTIONS:"
echo ""

echo "🟢 OPTION 1: Firefox Developer Edition (RECOMMENDED)"
echo "   ✅ Allows unsigned extensions permanently"
echo "   ✅ No signing required"
echo "   ✅ Professional development features"
echo "   📥 Download: $FIREFOX_DEV_URL"
echo "   📋 Steps:"
echo "      1. Install Firefox Developer Edition"
echo "      2. Open Developer Edition"
echo "      3. Go to: about:addons"
echo "      4. Click gear icon → 'Install Add-on From File'"
echo "      5. Select: $EXTENSION_XPI"
echo "      6. Click 'Add' (ignore unsigned warning)"
echo ""

echo "🟡 OPTION 2: Firefox Nightly"
echo "   ✅ Also allows unsigned extensions"
echo "   ⚠️  More experimental/unstable"
echo "   📋 Similar steps to Developer Edition"
echo ""

echo "🟠 OPTION 3: Regular Firefox (Advanced)"
echo "   ⚠️  Requires config changes"
echo "   📋 Steps:"
echo "      1. Go to: about:config"
echo "      2. Search: xpinstall.signatures.required"
echo "      3. Set to: false"
echo "      4. Go to: about:addons"
echo "      5. Install from file: $EXTENSION_XPI"
echo "   ⚠️  Note: Mozilla may remove this option in future"
echo ""

echo "🔵 OPTION 4: Enterprise Policy (Advanced)"
echo "   ✅ Most permanent solution"
echo "   🔧 Requires system-level configuration"
echo "   📋 Would you like me to set this up?"
echo ""

echo "❓ Which option would you like to use?"
echo "   1) Download Firefox Developer Edition"
echo "   2) Try regular Firefox with config change"
echo "   3) Set up Enterprise Policy"
echo "   4) Just show me the file location"
echo ""

read -p "Enter choice (1-4): " choice

case $choice in
    1)
        echo "🌐 Opening Firefox Developer Edition download page..."
        xdg-open "$FIREFOX_DEV_URL" 2>/dev/null || echo "Please visit: $FIREFOX_DEV_URL"
        echo "📋 After installation, use the steps above to install: $EXTENSION_XPI"
        ;;
    2)
        echo "🔧 Setting up regular Firefox..."
        echo "📋 Manual steps required:"
        echo "   1. Open Firefox"
        echo "   2. Go to: about:config"
        echo "   3. Accept the risk warning"
        echo "   4. Search: xpinstall.signatures.required"
        echo "   5. Click the toggle to set it to 'false'"
        echo "   6. Go to: about:addons"
        echo "   7. Click gear → 'Install Add-on From File'"
        echo "   8. Select: $EXTENSION_XPI"
        ;;
    3)
        echo "🏢 Setting up Enterprise Policy..."
        # Create enterprise policy
        sudo mkdir -p /etc/firefox/policies
        cat << EOF | sudo tee /etc/firefox/policies/policies.json
{
  "policies": {
    "ExtensionSettings": {
      "ai-dynamic-colors@dotfiles": {
        "installation_mode": "allowed",
        "allowed_types": ["extension"]
      }
    },
    "Preferences": {
      "xpinstall.signatures.required": false
    }
  }
}
EOF
        echo "✅ Enterprise policy created"
        echo "📋 Now install the extension from: $EXTENSION_XPI"
        ;;
    4)
        echo "📁 Extension package location:"
        echo "   $EXTENSION_XPI"
        echo ""
        echo "📋 To install manually:"
        echo "   1. Open Firefox"
        echo "   2. Go to: about:addons"
        echo "   3. Click gear icon → 'Install Add-on From File'"
        echo "   4. Select the file above"
        ;;
    *)
        echo "❌ Invalid choice"
        ;;
esac

echo ""
echo "🎨 Once installed permanently, your extension will:"
echo "   ✅ Survive Firefox restarts"
echo "   ✅ Auto-update themes from wallpaper changes"
echo "   ✅ Work across all tabs and windows"
echo ""
echo "🚀 Color server auto-starts with Hyprland!" 