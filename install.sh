#!/bin/bash
# Threads MCP Server - One-line Installation Script
# Usage: curl -sSL https://raw.githubusercontent.com/sergekostenchuk/threads-mcp/main/install.sh | bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="https://github.com/sergekostenchuk/threads-mcp"
INSTALL_DIR="$HOME/.local/share/threads-mcp"
BIN_DIR="$HOME/.local/bin"
CONFIG_DIR="$HOME/.config/threads-mcp"

# Functions
print_header() {
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}    Threads MCP Server Installation${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo ""
}

print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

check_requirements() {
    print_info "Checking system requirements..."
    
    # Check Node.js version
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed"
        print_info "Please install Node.js 18+ from https://nodejs.org"
        exit 1
    fi
    
    NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
    if [ "$NODE_VERSION" -lt 18 ]; then
        print_error "Node.js 18 or higher is required (found v$NODE_VERSION)"
        exit 1
    fi
    print_success "Node.js v$NODE_VERSION found"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed"
        exit 1
    fi
    print_success "npm is installed"
    
    # Check git (optional)
    if command -v git &> /dev/null; then
        print_success "git is installed (updates enabled)"
        HAS_GIT=true
    else
        print_info "git not found (manual updates required)"
        HAS_GIT=false
    fi
    
    # Check Docker (optional)
    if command -v docker &> /dev/null; then
        print_success "Docker is installed (container mode available)"
        HAS_DOCKER=true
    else
        print_info "Docker not found (native mode only)"
        HAS_DOCKER=false
    fi
}

create_directories() {
    print_info "Creating directories..."
    mkdir -p "$INSTALL_DIR"
    mkdir -p "$BIN_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$CONFIG_DIR/data"
    mkdir -p "$CONFIG_DIR/logs"
    print_success "Directories created"
}

download_and_install() {
    print_info "Downloading Threads MCP..."
    
    if [ "$HAS_GIT" = true ]; then
        # Clone with git
        if [ -d "$INSTALL_DIR/.git" ]; then
            print_info "Updating existing installation..."
            cd "$INSTALL_DIR"
            git pull origin main
        else
            git clone "$REPO_URL" "$INSTALL_DIR"
        fi
    else
        # Download release archive
        LATEST_RELEASE=$(curl -s https://api.github.com/repos/sergekostenchuk/threads-mcp/releases/latest | grep "tarball_url" | cut -d '"' -f 4)
        if [ -z "$LATEST_RELEASE" ]; then
            # Fallback to main branch if no releases
            LATEST_RELEASE="https://github.com/sergekostenchuk/threads-mcp/archive/refs/heads/main.tar.gz"
        fi
        curl -L "$LATEST_RELEASE" | tar xz -C "$INSTALL_DIR" --strip-components=1
    fi
    print_success "Downloaded successfully"
    
    # Install Node packages
    print_info "Installing Node.js packages..."
    cd "$INSTALL_DIR"
    npm install --production
    print_success "Node packages installed"
    
    # Build TypeScript if needed
    if [ -f "tsconfig.json" ]; then
        print_info "Building TypeScript..."
        npm run build
        print_success "TypeScript built"
    fi
    
    # Create executable
    print_info "Creating executable..."
    cat > "$BIN_DIR/threads-mcp" << 'EOF'
#!/usr/bin/env node
const path = require('path');
process.env.NODE_PATH = path.join(process.env.HOME, '.local/share/threads-mcp/node_modules');
require('module').Module._initPaths();
require(path.join(process.env.HOME, '.local/share/threads-mcp/src/index.js'));
EOF
    chmod +x "$BIN_DIR/threads-mcp"
    print_success "Executable created"
}

setup_configuration() {
    print_info "Setting up configuration..."
    
    if [ ! -f "$CONFIG_DIR/.env" ]; then
        cp "$INSTALL_DIR/.env.example" "$CONFIG_DIR/.env"
        print_info "Configuration template created at $CONFIG_DIR/.env"
        print_info "Please edit this file with your Threads App credentials"
    else
        print_info "Configuration already exists, skipping..."
    fi
    
    # Create config symlink
    ln -sf "$CONFIG_DIR/.env" "$INSTALL_DIR/.env" 2>/dev/null || true
    
    # Add to PATH if needed
    if [[ ":$PATH:" != *":$BIN_DIR:"* ]]; then
        print_info "Adding $BIN_DIR to PATH..."
        
        # Detect shell
        if [ -n "$ZSH_VERSION" ]; then
            SHELL_RC="$HOME/.zshrc"
        elif [ -n "$BASH_VERSION" ]; then
            SHELL_RC="$HOME/.bashrc"
        else
            SHELL_RC="$HOME/.profile"
        fi
        
        echo "" >> "$SHELL_RC"
        echo "# Threads MCP Server" >> "$SHELL_RC"
        echo "export PATH=\"$BIN_DIR:\$PATH\"" >> "$SHELL_RC"
        
        print_success "PATH updated in $SHELL_RC"
        print_info "Run 'source $SHELL_RC' or restart your terminal"
    fi
}

setup_docker() {
    if [ "$HAS_DOCKER" = true ]; then
        print_info "Setting up Docker..."
        cd "$INSTALL_DIR"
        
        # Build Docker image
        docker build -t threads-mcp:latest .
        print_success "Docker image built"
        
        # Create docker-compose override
        if [ ! -f "$CONFIG_DIR/docker-compose.override.yml" ]; then
            cat > "$CONFIG_DIR/docker-compose.override.yml" << EOF
version: '3.8'
services:
  threads-mcp:
    env_file:
      - $CONFIG_DIR/.env
    volumes:
      - $CONFIG_DIR/data:/data
      - $CONFIG_DIR/logs:/logs
EOF
            print_success "Docker compose override created"
        fi
    fi
}

setup_oauth_helper() {
    print_info "Setting up OAuth helper..."
    
    # Create OAuth helper script
    cat > "$BIN_DIR/threads-oauth" << 'EOF'
#!/usr/bin/env node
const path = require('path');
process.env.NODE_PATH = path.join(process.env.HOME, '.local/share/threads-mcp/node_modules');
require('module').Module._initPaths();
require(path.join(process.env.HOME, '.local/share/threads-mcp/src/oauth-server.js'));
EOF
    chmod +x "$BIN_DIR/threads-oauth"
    print_success "OAuth helper created"
}

verify_installation() {
    print_info "Verifying installation..."
    
    if [ -x "$BIN_DIR/threads-mcp" ]; then
        print_success "threads-mcp command is available"
    else
        print_error "threads-mcp command not found"
        exit 1
    fi
    
    # Test Node modules
    cd "$INSTALL_DIR"
    if node -e "require('@modelcontextprotocol/sdk')" 2>/dev/null; then
        print_success "Node modules installed correctly"
    else
        print_error "Failed to load Node modules"
        exit 1
    fi
}

print_next_steps() {
    echo ""
    print_header
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Register Threads App: ${BLUE}https://developers.facebook.com/apps/${NC}"
    echo "2. Edit configuration: ${BLUE}$CONFIG_DIR/.env${NC}"
    echo "3. Add your App ID and Secret"
    echo "4. Run OAuth setup: ${BLUE}threads-oauth${NC}"
    echo "5. Start the MCP server: ${BLUE}threads-mcp${NC}"
    echo ""
    if [ "$HAS_DOCKER" = true ]; then
        echo "Docker mode available:"
        echo "  ${BLUE}cd $INSTALL_DIR && docker-compose up -d${NC}"
    fi
    echo ""
    echo "Add to Claude Desktop config:"
    echo "  ${BLUE}$HOME/Library/Application Support/Claude/claude_desktop_config.json${NC}"
    echo ""
    echo "Documentation: ${BLUE}$REPO_URL${NC}"
    echo ""
}

# Main installation flow
main() {
    print_header
    check_requirements
    create_directories
    download_and_install
    setup_configuration
    setup_docker
    setup_oauth_helper
    verify_installation
    print_next_steps
}

# Run installation
main "$@"