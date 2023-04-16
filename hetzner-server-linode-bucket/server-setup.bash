#!/bin/bash
# This script is used to setup debian servers for the first time
# It is not intended to be run on a regular basis

# Get server ip from .tfouputs
# Structure is web_server_ip = ""
# SERVER_IP should be equal to the ip address
SERVER_IP=$(grep web_server_ip .tfout | cut -d '"' -f 2)

# Copy this file to the server and run it as root
scp server-setup.sh root@$SERVER_IP:/root

# Update the system
sudo apt-get update
sudo apt-get upgrade -y

# Install the packages we need
sudo apt-get install -y curl wget vim git zsh tmux

##### DOCKER INSTALLATION #####

# Install the docker dependencies
sudo apt-get install ca-certificates curl gnupg2 software-properties-common -y

# Add the docker gpg key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker-archive-keyring.gpg

# Setup the docker repository
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install docker
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

##### USER SETUP #####

# Create user deploy
sudo useradd --home /home/deploy --create-home --shell /bin/zsh deploy

# Add user to docker group
sudo usermod -aG docker deploy

##### SSH SETUP #####

# Generate ssh key
ssh-keygen -q -t ed25519 -N '' -f ~/.ssh/id_ed25519
