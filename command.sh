cd ~/boost-game
cat > command.sh << 'EOF'
#!/data/data/com.termux/files/usr/bin/bash
pkg update -y && pkg upgrade -y
pkg install root-repo x11-repo tur-repo -y
pkg install termux-tools git -y
pkg autoclean
chmod +x boost.sh
echo "✅ Setup selesai, sekarang jalanin: bash boost.sh"
EOF

chmod +x command.sh
