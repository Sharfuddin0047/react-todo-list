#!/bin/bash
# setup.sh - install Docker only if not already installed

if ! command -v docker &> /dev/null; then
    echo "Docker not found. Installing..."
    sudo apt update
    sudo apt install -y docker.io
    sudo systemctl enable docker
    sudo systemctl start docker
    sudo usermod -aG docker $USER
    echo "Docker installed. You may need to log out/in for group changes to take effect."
else
    echo "Docker already installed. Skipping..."
fi
