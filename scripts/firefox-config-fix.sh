#!/bin/bash

# Firefox Configuration Fix for Unsigned Extensions
# Comprehensive solution for modern Firefox versions

echo "🔧 Firefox Configuration Fix for Unsigned Extensions"
echo "===================================================="
echo ""

echo "🔍 Detected Firefox version: $(firefox --version)"
echo ""

echo "📋 STEP-BY-STEP SOLUTION:"
echo ""

echo "1️⃣ CLOSE FIREFOX COMPLETELY"
echo "   - Close all Firefox windows"
echo "   - Check task manager: pkill firefox"
echo ""

read -p "Press Enter when Firefox is completely closed..."

echo ""
echo "2️⃣ APPLYING FIREFOX SETTINGS..."

# Create Firefox policy file for system-wide settings
echo "🏢 Creating system-wide Firefox policy..."
sudo mkdir -p /etc/firefox/policies

cat << 'EOF' | sudo tee /etc/firefox/policies/policies.json > /dev/null
{
  "policies": {
    "Preferences": {
      "xpinstall.signatures.required": {
        "Value": false,
        "Status": "locked"
      },
      "extensions.experiments.enabled": {
        "Value": true,
        "Status": "default"
      },
      "extensions.legacy.enabled": {
        "Value": true,
        "Status": "default"
      }
    }
  }
}
EOF

echo "✅ System policy created: /etc/firefox/policies/policies.json"
echo ""

echo "3️⃣ ALTERNATIVE: User-specific prefs.js modification"
echo ""

# Find Firefox profile
FIREFOX_PROFILE=$(find ~/.mozilla/firefox -name "*.default*" -type d | head -1)
if [[ -n "$FIREFOX_PROFILE" ]]; then
    echo "📁 Found Firefox profile: $FIREFOX_PROFILE"
    
    # Backup existing prefs
    if [[ -f "$FIREFOX_PROFILE/prefs.js" ]]; then
        cp "$FIREFOX_PROFILE/prefs.js" "$FIREFOX_PROFILE/prefs.js.backup"
        echo "📦 Backed up existing prefs.js"
    fi
    
    # Add our preferences
    cat >> "$FIREFOX_PROFILE/prefs.js" << 'EOF'

// AI Extension Configuration - Allow unsigned extensions
user_pref("xpinstall.signatures.required", false);
user_pref("extensions.experiments.enabled", true);
user_pref("extensions.legacy.enabled", true);
user_pref("devtools.chrome.enabled", true);
user_pref("devtools.debugger.remote-enabled", true);
EOF
    
    echo "✅ Added preferences to profile prefs.js"
else
    echo "⚠️  Could not find Firefox profile directory"
fi

echo ""
echo "4️⃣ LAUNCH FIREFOX IN DEVELOPER MODE"
echo ""

# Create launcher script for developer mode
cat > /tmp/launch-firefox-dev.sh << 'EOF'
#!/bin/bash
echo "🚀 Launching Firefox in Developer Mode..."
firefox --new-instance --profile-manager &
sleep 2
echo ""
echo "📋 In the Profile Manager:"
echo "   1. Select your profile"
echo "   2. Click 'Start Firefox'"
echo ""
echo "📋 Once Firefox opens:"
echo "   1. Go to: about:config"
echo "   2. Search: xpinstall.signatures.required"
echo "   3. Verify it shows 'false' (and locked)"
echo "   4. Go to: about:addons"
echo "   5. Click gear → 'Install Add-on From File'"
echo "   6. Select: /home/martin/dotfiles/firefox-ai-extension.xpi"
EOF

chmod +x /tmp/launch-firefox-dev.sh

echo "🎯 FINAL INSTALLATION STEPS:"
echo ""
echo "5️⃣ VERIFY AND INSTALL"
echo "   Run: /tmp/launch-firefox-dev.sh"
echo "   OR manually:"
echo "   1. Open Firefox"
echo "   2. about:config → verify xpinstall.signatures.required = false"
echo "   3. about:addons → gear → Install Add-on From File"
echo "   4. Select: $(pwd)/firefox-ai-extension.xpi"
echo ""

echo "🔥 ALTERNATIVE: Firefox Developer Edition (GUARANTEED)"
echo "   If the above doesn't work, Firefox Developer Edition"
echo "   ALWAYS allows unsigned extensions without any config:"
echo ""
echo "   📥 Download: https://www.mozilla.org/firefox/developer/"
echo "   📋 Install and use the same .xpi file"
echo ""

echo "❓ Would you like to:"
echo "   1) Launch Firefox with dev settings now"
echo "   2) Download Firefox Developer Edition" 
echo "   3) Show .xpi file location only"
echo ""

read -p "Enter choice (1-3): " choice

case $choice in
    1)
        echo "🚀 Launching Firefox..."
        /tmp/launch-firefox-dev.sh
        ;;
    2)
        echo "🌐 Opening Firefox Developer Edition download..."
        xdg-open "https://www.mozilla.org/firefox/developer/" 2>/dev/null
        echo "📋 After installation, install: $(pwd)/firefox-ai-extension.xpi"
        ;;
    3)
        echo "📁 Extension file: $(pwd)/firefox-ai-extension.xpi"
        echo "📋 Use about:addons → gear → Install Add-on From File"
        ;;
esac

echo ""
echo "🎨 Once installed, your AI theming will be permanent!" 