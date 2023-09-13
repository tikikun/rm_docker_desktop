#!/bin/bash

echo "Starting Combo 1 Installation..."

# Step 1: Install colima
echo "Step 1: Installing colima..."
brew install colima
if [ $? -ne 0 ]; then
    echo "Error installing colima."
    exit 1
fi

# Solve potential issues with credentials
echo "Solving potential issues with credentials..."
brew install docker-credential-helper
if [ $? -ne 0 ]; then
    echo "Error installing docker-credential-helper."
    exit 1
fi

# Step 2: Install docker
echo "Step 2: Installing Docker..."
brew install docker
if [ $? -ne 0 ]; then
    echo "Error installing Docker."
    exit 1
fi

# Step 3: Install buildx
echo "Step 3: Installing buildx..."
brew install gh || { echo "Error installing github cli client."; exit 1; }

RELEASE_FILE_SUFFIX='darwin-arm64'
gh release download --repo 'github.com/docker/buildx' --pattern "*.$RELEASE_FILE_SUFFIX"
mkdir -p ~/.docker/cli-plugins
mv -f *.$RELEASE_FILE_SUFFIX ~/.docker/cli-plugins/docker-buildx
chmod +x ~/.docker/cli-plugins/docker-buildx
docker buildx version
if [ $? -ne 0 ]; then
    echo "Error verifying buildx installation."
    exit 1
fi

# Step 4: Run colima
echo "Step 4: Running colima..."
colima start --arch aarch64 --vm-type vz --cpu $(sysctl -n hw.ncpu) --memory $(sysctl -n hw.memsize | awk '{print int($0/1024/1024/1024)}')

# Verify docker is running
docker info
if [ $? -ne 0 ]; then
    echo "Error verifying Docker installation."
    exit 1
fi

# Step 5: Install lazydocker
echo "Step 5: Installing lazydocker..."
brew install lazydocker
if [ $? -ne 0 ]; then
    echo "Error installing lazydocker."
    exit 1
fi

# Step 6: Set up docker host for lazydocker
echo "Step 6: Setting up docker host for lazydocker..."
echo export DOCKER_HOST="unix://$HOME/.colima/docker.sock" >> ~/.zshrc
echo alias colima.quick='colima start --arch aarch64 --vm-type vz --cpu $(sysctl -n hw.ncpu) --memory $(sysctl -n hw.memsize | awk "{print int(\$0/1024/1024/1024)}")' >> ~/.zshrc

# Verify if user uses other shells like bash
default_shell=$(basename "$SHELL")
if [ "$default_shell" != "zsh" ]; then
    echo "It seems you're not using ZSH. Adding to $default_shell rc file..."
    echo export DOCKER_HOST="unix://$HOME/.colima/docker.sock" >> ~/.$default_shell"rc"
    echo "alias colima.quick='colima start --arch aarch64 --vm-type vz --cpu \$(sysctl -n hw.ncpu) --memory \$(sysctl -n hw.memsize | awk \"{print int(\$0/1024/1024/1024)}\")'" >> ~/.$default_shell"rc"
fi

# Step 7: Run lazydocker
echo "Step 7: Running lazydocker..."
lazydocker

echo "All steps completed successfully!"
