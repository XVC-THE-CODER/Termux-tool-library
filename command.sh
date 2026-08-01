#!/data/data/com.termux/files/usr/bin/bash
termux-wake-lock
termux-setup-storage
pkg update -y
pkg upgrade -y
pkg install -y root-repo
pkg install -y termux-tools termux-api termux-exec termux-services android-tools tsu -y
clear
