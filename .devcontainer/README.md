# Development Container Configuration

This directory contains the development container configuration for the Raspberry Pi HDMI Tester project. It enables consistent development environments across GitHub Codespaces and local VS Code Dev Containers.

## What's Included

### Base System
- **Ubuntu 24.04 LTS** base image
- **User**: `vscode` with sudo privileges
- **Shell**: Bash with custom aliases and helpful prompts

### Raspberry Pi Build Tools
- **pi-gen** - Official Raspberry Pi OS image builder (pre-cloned)
- **QEMU** - ARM emulation for cross-platform building
  - qemu-user-static
  - qemu-utils
  - qemu-system-arm
  - binfmt-support enabled for ARM binaries
- **debootstrap** - Bootstrap Debian-based systems
- **kpartx** - Partition table manipulation
- **parted** - Partition editing tool
- **dosfstools** - FAT filesystem utilities

### Development Tools
- **Build essentials** - gcc, g++, make, cmake
- **Python 3** with pip and development headers
- **Git** with sensible defaults
- **GitHub CLI** (gh)
- **Docker-in-Docker** - For containerized builds
- **ShellCheck** - Shell script linting

### Utilities
- **Image manipulation**: ImageMagick
- **Audio tools**: SoX, FFmpeg
- **Archive tools**: zip, unzip, tar, gzip, xz-utils
- **Debugging**: strace, ltrace, htop
- **File management**: tree, ncdu
- **Terminal multiplexers**: tmux, screen

### VS Code Extensions
Automatically installed:
- Python language support
- Docker support
- YAML support
- Git lens
- Makefile tools
- ShellCheck integration
- Shell formatter
- Spell checker

## Container Features

### Custom Helper Commands

Once inside the container, you have access to:

```bash
# Check all build dependencies
check-deps

# Set up pi-gen working directory
setup-pi-gen
```

### Environment Variables

- `PI_GEN_BASE=/opt/pi-gen` - Location of pi-gen base installation
- `DEBIAN_FRONTEND=noninteractive` - Non-interactive apt
- `TZ=UTC` - Timezone set to UTC

### Privileged Mode

The container runs in privileged mode to support:
- Loop device mounting (kpartx)
- Image building operations
- Docker-in-Docker functionality

## Resource Requirements

- **CPU**: Minimum 2 cores (4+ recommended)
- **RAM**: Minimum 4GB (8GB+ recommended)
- **Storage**: Minimum 32GB free space
  - pi-gen builds require ~4GB per build
  - Multiple builds and caching increase requirements

## Files

### `devcontainer.json`
Main configuration file that defines:
- Container settings
- VS Code customizations
- Port forwarding
- Post-creation commands
- Features and extensions

### `Dockerfile`
Defines the container image with:
- All system dependencies
- Tool installations
- User setup
- Helper scripts
- Welcome message

### `post-create.sh`
Runs after container creation to:
- Create project directory structure
- Set file permissions
- Check dependencies
- Configure git
- Display helpful setup information

### `.dockerignore`
Excludes files from Docker context:
- Git files
- Build outputs
- Temporary files
- Cache directories

## Usage

### First Time Setup

1. **Open in Codespaces/Dev Container**
   - The container will build automatically
   - Wait for post-create script to finish

2. **Verify Setup**
   ```bash
   check-deps
   ```

3. **Initialize pi-gen**
   ```bash
   setup-pi-gen
   ```

### Rebuilding the Container

If you modify the Dockerfile or devcontainer.json:

**In Codespaces:**
```
Command Palette (F1) → Codespaces: Rebuild Container
```

**In VS Code Dev Containers:**
```
Command Palette (F1) → Dev Containers: Rebuild Container
```

### Troubleshooting

**Container won't start:**
- Check Docker daemon is running
- Verify system meets resource requirements
- Review Docker logs for errors

**Build tools not working:**
- Run `check-deps` to verify installations
- Check for permission issues with `sudo`
- Verify QEMU binfmt is enabled: `update-binfmts --display qemu-arm`

**Out of disk space:**
- Clean up old builds: `sudo rm -rf build/work/*`
- Remove Docker images: `docker system prune -a`
- Increase allocated storage in container settings

## Customization

### Adding More Tools

Edit `Dockerfile` and add to the `apt-get install` section:

```dockerfile
RUN apt-get update && apt-get install -y \
    your-package-here \
    && rm -rf /var/lib/apt/lists/*
```

### Adding VS Code Extensions

Edit `devcontainer.json` under `customizations.vscode.extensions`:

```json
"extensions": [
    "existing.extension",
    "publisher.new-extension"
]
```

### Modifying Post-Create Steps

Edit `post-create.sh` to add custom initialization:

```bash
# Your custom setup commands
echo "Running custom setup..."
```

## Security Notes

- Container runs in **privileged mode** for image building
- User `vscode` has **passwordless sudo**
- Suitable for development only, not production
- Keep container and base images updated

## Performance Tips

1. **Use build caching**: Don't clean pi-gen work directory between builds
2. **Allocate more resources**: Increase CPU/RAM in container settings
3. **Use fast storage**: SSD recommended for host system
4. **Close unused applications**: Free up system resources during builds

## Support

For issues with the dev container:
1. Check this README and troubleshooting section
2. Review container logs
3. Open an issue on GitHub with details

## References

- [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
- [GitHub Codespaces](https://github.com/features/codespaces)
- [pi-gen Documentation](https://github.com/RPi-Distro/pi-gen)
