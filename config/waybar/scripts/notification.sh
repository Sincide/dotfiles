#!/bin/bash

if dunstctl is-paused | grep -q "false"; then
    echo "󰂚"  # Bell icon from Nerd Fonts
else
    echo "󰂛"  # Bell-off icon from Nerd Fonts
fi 