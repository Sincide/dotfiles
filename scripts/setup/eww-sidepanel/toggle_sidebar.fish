#!/usr/bin/env fish
# Toggle EWW sidebar script (Fish Shell)

# Check if sidebar is open
if eww active-windows | grep -q "sidebar_window"
    # Close sidebar with slide-out animation
    eww close sidebar_window
else
    # Open sidebar with slide-in animation
    eww open sidebar_window
end