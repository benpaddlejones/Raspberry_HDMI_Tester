# Use Ubuntu 24.04 as base (matches the Codespaces environment)
FROM ubuntu:24.04

# Avoid prompts from apt
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Create vscode user with sudo access
# Handle the case where GID/UID 1000 might already exist
RUN apt-get update \
    && apt-get install -y sudo \
    && groupadd --gid 1000 vscode 2>/dev/null || groupmod -n vscode $(getent group 1000 | cut -d: -f1) \
    && useradd --uid 1000 --gid 1000 -m -s /bin/bash vscode 2>/dev/null || usermod -l vscode -d /home/vscode -m $(getent passwd 1000 | cut -d: -f1) \
    && echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/vscode \
    && chmod 0440 /etc/sudoers.d/vscode

# Install base dependencies
RUN apt-get update && apt-get install -y \
    # Essential build tools
    build-essential \
    gcc \
    g++ \
    make \
    cmake \
    git \
    curl \
    wget \
    ca-certificates \
    gnupg \
    lsb-release \
    # Python and utilities
    python3 \
    python3-pip \
    python3-dev \
    # Raspberry Pi image building tools
    qemu-user-static \
    qemu-utils \
    qemu-system-arm \
    binfmt-support \
    debootstrap \
    kpartx \
    parted \
    dosfstools \
    rsync \
    # Archive and compression tools
    zip \
    unzip \
    bzip2 \
    xz-utils \
    tar \
    gzip \
    libarchive-tools \
    cpio \
    # Image manipulation
    imagemagick \
    # Audio tools (for creating test audio files)
    sox \
    ffmpeg \
    # File system tools
    kmod \
    udev \
    systemd \
    # Debian package tools
    dpkg-dev \
    debhelper \
    devscripts \
    # Utilities
    vim \
    nano \
    less \
    tree \
    file \
    strace \
    ltrace \
    jq \
    bc \
    coreutils \
    util-linux \
    fdisk \
    mount \
    # Network tools
    net-tools \
    iproute2 \
    iputils-ping \
    dnsutils \
    # Shell tools
    shellcheck \
    bash-completion \
    # Additional tools for pi-gen
    quilt \
    multistrap \
    fakeroot \
    fakechroot \
    proot \
    # Documentation
    man-db \
    manpages \
    && rm -rf /var/lib/apt/lists/*

# Install additional Python packages
RUN pip3 install --no-cache-dir --break-system-packages \
    pillow \
    pyyaml \
    jinja2 \
    requests

# Set up QEMU for ARM emulation
RUN update-binfmts --enable qemu-arm
RUN update-binfmts --enable qemu-aarch64

# Create workspace directories
RUN mkdir -p /workspace/build /workspace/output \
    && chown -R vscode:vscode /workspace

# Set working directory
WORKDIR /workspace

# Clone pi-gen repository (official Raspberry Pi OS image builder)
RUN git clone https://github.com/RPi-Distro/pi-gen.git /opt/pi-gen \
    && chown -R vscode:vscode /opt/pi-gen

# Create symlink for easy access
RUN ln -s /opt/pi-gen /workspace/pi-gen-base

# Install additional utilities for debugging
RUN apt-get update && apt-get install -y \
    htop \
    ncdu \
    tmux \
    screen \
    && rm -rf /var/lib/apt/lists/*

# Set up git config template
RUN git config --system core.autocrlf input \
    && git config --system core.eol lf \
    && git config --system init.defaultBranch main

# Add helper scripts directory
RUN mkdir -p /usr/local/bin/helpers

# Create a helper script for checking build dependencies
RUN echo '#!/bin/bash\n\
echo "Checking Raspberry Pi image build dependencies..."\n\
echo ""\n\
echo "Required tools:"\n\
command -v qemu-arm-static >/dev/null 2>&1 && echo "✓ qemu-arm-static" || echo "✗ qemu-arm-static"\n\
command -v debootstrap >/dev/null 2>&1 && echo "✓ debootstrap" || echo "✗ debootstrap"\n\
command -v kpartx >/dev/null 2>&1 && echo "✓ kpartx" || echo "✗ kpartx"\n\
command -v parted >/dev/null 2>&1 && echo "✓ parted" || echo "✗ parted"\n\
command -v git >/dev/null 2>&1 && echo "✓ git" || echo "✗ git"\n\
command -v docker >/dev/null 2>&1 && echo "✓ docker" || echo "✗ docker"\n\
command -v python3 >/dev/null 2>&1 && echo "✓ python3" || echo "✗ python3"\n\
echo ""\n\
echo "Disk space:"\n\
df -h /workspace | tail -1 | awk '\''{print "Available: " $4}'\'' \n\
echo ""\n\
echo "QEMU ARM support:"\n\
update-binfmts --display qemu-arm | head -3\n\
' > /usr/local/bin/check-deps && chmod +x /usr/local/bin/check-deps

# Create a helper script for quick pi-gen setup
RUN echo '#!/bin/bash\n\
echo "Setting up pi-gen working directory..."\n\
if [ ! -d "pi-gen-work" ]; then\n\
  cp -r /opt/pi-gen pi-gen-work\n\
  echo "✓ Created pi-gen-work directory"\n\
else\n\
  echo "✓ pi-gen-work directory already exists"\n\
fi\n\
' > /usr/local/bin/setup-pi-gen && chmod +x /usr/local/bin/setup-pi-gen

# Set environment variables for builds
ENV PATH="/usr/local/bin/helpers:${PATH}"
ENV PI_GEN_BASE="/opt/pi-gen"

# Switch to vscode user
USER vscode

# Set up bash aliases and helpers
RUN echo 'alias ll="ls -lah"' >> ~/.bashrc \
    && echo 'alias gs="git status"' >> ~/.bashrc \
    && echo 'alias check-deps="/usr/local/bin/check-deps"' >> ~/.bashrc \
    && echo 'export PS1="\[\e[32m\]\u@\h\[\e[0m\]:\[\e[34m\]\w\[\e[0m\]\$ "' >> ~/.bashrc

# Display welcome message on shell start
RUN echo 'cat << "EOF"' >> ~/.bashrc \
    && echo '' >> ~/.bashrc \
    && echo '╔═══════════════════════════════════════════════════════════╗' >> ~/.bashrc \
    && echo '║  Raspberry Pi HDMI Tester - Development Environment      ║' >> ~/.bashrc \
    && echo '╚═══════════════════════════════════════════════════════════╝' >> ~/.bashrc \
    && echo '' >> ~/.bashrc \
    && echo 'Quick commands:' >> ~/.bashrc \
    && echo '  check-deps      - Verify build dependencies' >> ~/.bashrc \
    && echo '  setup-pi-gen    - Set up pi-gen working directory' >> ~/.bashrc \
    && echo '' >> ~/.bashrc \
    && echo 'Documentation: See README.md for full instructions' >> ~/.bashrc \
    && echo '' >> ~/.bashrc \
    && echo 'EOF' >> ~/.bashrc

# Set default shell to bash
ENV SHELL=/bin/bash

# Keep container running
CMD ["/bin/bash"]
