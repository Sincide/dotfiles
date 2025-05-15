#!/bin/bash

if dunstctl is-paused | grep -q "false"; then
    echo "On"
else
    echo "Off"
fi 