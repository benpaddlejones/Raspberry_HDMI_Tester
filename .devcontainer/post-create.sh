#!/bin/bash
# Post-create script for dev container setup
# This runs after the container is created

set -e

echo "=================================================="
echo "Running post-create setup for HDMI Tester project"
echo "=================================================="
echo ""

# Make sure we're in the workspace
cd /workspaces/Raspberry_HDMI_Tester || exit 1

# Create necessary directories
echo "📁 Creating project directories..."
mkdir -p build/stage-custom/{00-install-packages,01-test-image,02-audio-test,03-autostart}
mkdir -p assets
mkdir -p scripts
mkdir -p docs
mkdir -p tests
echo "✓ Directories created"
echo ""

# Set proper permissions
echo "🔐 Setting permissions..."
chmod +x scripts/*.sh 2>/dev/null || true
chmod +x tests/*.sh 2>/dev/null || true
chmod +x .devcontainer/*.sh 2>/dev/null || true
echo "✓ Permissions set"
echo ""

# Check dependencies
echo "🔍 Checking build dependencies..."
if [ -x /usr/local/bin/check-deps ]; then
    /usr/local/bin/check-deps
else
    echo "⚠️  check-deps script not found, checking manually..."
    command -v qemu-arm-static >/dev/null 2>&1 && echo "✓ qemu-arm-static" || echo "✗ qemu-arm-static"
    command -v debootstrap >/dev/null 2>&1 && echo "✓ debootstrap" || echo "✗ debootstrap"
    command -v kpartx >/dev/null 2>&1 && echo "✓ kpartx" || echo "✗ kpartx"
    command -v parted >/dev/null 2>&1 && echo "✓ parted" || echo "✗ parted"
    command -v git >/dev/null 2>&1 && echo "✓ git" || echo "✗ git"
fi
echo ""

# Initialize git hooks (if needed)
if [ -d .git ]; then
    echo "🎣 Setting up git configuration..."
    git config --local core.autocrlf input
    git config --local core.eol lf
    echo "✓ Git configured"
    echo ""
fi

# Display helpful information
echo "=================================================="
echo "✓ Setup complete!"
echo "=================================================="
echo ""
echo "Next steps:"
echo "  1. Review the README.md for project overview"
echo "  2. Run 'setup-pi-gen' to initialize pi-gen workspace"
echo "  3. Create test assets in the assets/ directory"
echo "  4. Configure and run the build scripts"
echo ""
echo "Useful commands:"
echo "  check-deps    - Verify all dependencies are installed"
echo "  setup-pi-gen  - Set up pi-gen working directory"
echo ""
echo "Happy coding! 🚀"
echo ""
