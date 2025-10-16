# Copilot Instructions for Codespaces/Docker Configuration

## Overview

This comprehensive guide provides Copilot with definitive rules and best practices for creating and reviewing `.devcontainer`, `.vscode`, and Docker configurations. Following these instructions will ensure zero build failures and straightforward fixes when issues occur.

## How to Use This Document

### For Creating NEW Codespace Configurations

1. **Start with Core Principles** (Section 5)
2. **Follow Step-by-Step Creation Workflow** (Section 4)
3. **Apply LTS Version Strategy** (Section 6)
4. **Use Configuration Templates** (Sections 7-9)
5. **Run Pre-Deployment Validation** (Section 11)

### For Reviewing EXISTING Codespace Configurations

1. **Run Quick Diagnostic Commands** (Section 10)
2. **Execute Comprehensive Validation** (Section 11)
3. **Check Against Common Error Patterns** (Section 3)
4. **Apply fixes using Troubleshooting Guide** (Section 12)
5. **Re-validate after changes**

## Step-by-Step Codespace Creation Workflow

### Phase 1: Planning & Requirements Analysis

#### 1.1 Identify Project Requirements

```bash
# Create requirements checklist
echo "📋 Codespace Requirements Analysis" > codespace-requirements.md
echo "=================================" >> codespace-requirements.md
echo "" >> codespace-requirements.md
echo "## Programming Languages Needed:" >> codespace-requirements.md
echo "- [ ] Node.js (specify LTS version)" >> codespace-requirements.md
echo "- [ ] Python (specify stable version)" >> codespace-requirements.md
echo "- [ ] Other: _____________" >> codespace-requirements.md
echo "" >> codespace-requirements.md
echo "## Required Tools & Services:" >> codespace-requirements.md
echo "- [ ] Docker" >> codespace-requirements.md
echo "- [ ] Git" >> codespace-requirements.md
echo "- [ ] GitHub CLI" >> codespace-requirements.md
echo "- [ ] Database (PostgreSQL, MySQL, etc.)" >> codespace-requirements.md
echo "- [ ] Other: _____________" >> codespace-requirements.md
echo "" >> codespace-requirements.md
echo "## VS Code Extensions Needed:" >> codespace-requirements.md
echo "- [ ] Language-specific extensions" >> codespace-requirements.md
echo "- [ ] Formatters and linters" >> codespace-requirements.md
echo "- [ ] Debugging extensions" >> codespace-requirements.md
echo "- [ ] Other: _____________" >> codespace-requirements.md
```

#### 1.2 Choose Base Strategy

```bash
# Decision matrix for base approach
echo "🔍 Base Strategy Decision Matrix:"
echo "================================"
echo "Option 1: Feature-based (Recommended for most projects)"
echo "  ✅ Pros: Managed by Microsoft, automatic updates, consistent"
echo "  ❌ Cons: Less control, potential version delays"
echo ""
echo "Option 2: Dockerfile-based (For complex custom requirements)"
echo "  ✅ Pros: Full control, custom base images, complex setups"
echo "  ❌ Cons: More maintenance, manual updates, debugging complexity"
echo ""
echo "Option 3: Docker Compose (For multi-service applications)"
echo "  ✅ Pros: Multiple services, database integration, production-like"
echo "  ❌ Cons: Resource intensive, complex networking, slower startup"
```

### Phase 2: Directory Structure Creation

#### 2.1 Create Required Directories

```bash
# Create the essential directory structure
mkdir -p .devcontainer
mkdir -p .vscode
mkdir -p scripts

# Create placeholder files
touch .devcontainer/devcontainer.json
touch .devcontainer/post-create.sh
touch .devcontainer/post-start.sh
touch .vscode/settings.json
touch .vscode/tasks.json
touch .vscode/launch.json
touch .vscode/extensions.json

echo "📁 Created codespace directory structure"
```

#### 2.2 Make Scripts Executable

```bash
# Ensure all shell scripts are executable
chmod +x .devcontainer/*.sh
chmod +x scripts/*.sh 2>/dev/null || true
echo "🔧 Made scripts executable"
```

### Phase 3: Configuration File Creation

#### 3.1 Create devcontainer.json Template

```json
{
  "name": "PROJECT_NAME_HERE",
  "image": "mcr.microsoft.com/devcontainers/universal:4",

  // OPTION A: Use features (recommended)
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "22",
      "nodeGypDependencies": true
    },
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.13"
    },
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {}
  },

  // OPTION B: Use custom Dockerfile
  // "build": {
  //   "dockerfile": "Dockerfile",
  //   "context": ".."
  // },

  // Port forwarding
  "forwardPorts": [3000, 8080, 9229],
  "portsAttributes": {
    "3000": {
      "label": "Application",
      "onAutoForward": "notify"
    },
    "9229": {
      "label": "Debug",
      "onAutoForward": "silent"
    }
  },

  // Environment variables
  "remoteEnv": {
    "NODE_ENV": "development",
    "PYTHONPATH": "/workspace"
  },

  // Lifecycle commands
  "postCreateCommand": ".devcontainer/post-create.sh",
  "postStartCommand": ".devcontainer/post-start.sh",

  // VS Code customizations
  "customizations": {
    "vscode": {
      "extensions": [
        "GitHub.copilot",
        "GitHub.copilot-chat",
        "ms-python.python",
        "ms-python.pylance",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint"
      ],
      "settings": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
          "source.fixAll": "explicit"
        }
      }
    }
  }
}
```

#### 3.2 Create Post-Create Script Template

```bash
#!/bin/bash
# .devcontainer/post-create.sh

set -e
echo "🔄 Starting post-create setup..."

# Function to check command availability
check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        echo "✅ $1 is available"
        return 0
    else
        echo "❌ $1 is not available"
        return 1
    fi
}

# Wait for features to be ready (critical for avoiding 'command not found')
echo "⏳ Waiting for development tools to be ready..."
sleep 5

# Refresh shell environment to pick up new PATH
if [ -f ~/.bashrc ]; then
    source ~/.bashrc
fi

# Validate required commands are available
echo "🔍 Validating required commands..."
REQUIRED_COMMANDS=()

# Add commands based on your project needs
if grep -q "npm" package.json 2>/dev/null; then
    REQUIRED_COMMANDS+=("npm")
fi

if [ -f "requirements.txt" ]; then
    REQUIRED_COMMANDS+=("pip3")
fi

# Check each required command
for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if ! check_command "$cmd"; then
        echo "❌ Required command $cmd not found. This will cause installation failures."
        echo "💡 Try using full path or adding source ~/.bashrc before using $cmd"
        exit 1
    fi
done

# Install Node.js dependencies (if package.json exists)
if [ -f "package.json" ]; then
    echo "📦 Installing Node.js dependencies..."
    npm install
fi

# Install Python dependencies (if requirements.txt exists)
if [ -f "requirements.txt" ]; then
    echo "🐍 Installing Python dependencies..."
    pip3 install --break-system-packages -r requirements.txt
fi

# Create necessary directories
echo "📁 Setting up workspace directories..."
mkdir -p logs
mkdir -p temp
mkdir -p .vscode-remote

echo "🎉 Post-create setup completed successfully!"
```

#### 3.3 Create Post-Start Script Template

```bash
#!/bin/bash
# .devcontainer/post-start.sh

set -e
echo "🚀 Starting post-start setup..."

# Validate environment
echo "🔍 Validating development environment..."

# Check Node.js if needed
if [ -f "package.json" ]; then
    if command -v node >/dev/null 2>&1; then
        echo "✅ Node.js: $(node --version)"
        echo "✅ npm: $(npm --version)"
    else
        echo "⚠️ Node.js not found"
    fi
fi

# Check Python if needed
if [ -f "requirements.txt" ]; then
    if command -v python3 >/dev/null 2>&1; then
        echo "✅ Python: $(python3 --version)"
        echo "✅ pip: $(pip3 --version)"
    else
        echo "⚠️ Python not found"
    fi
fi

# Check port availability
echo "🔌 Checking port availability..."
PORTS=(3000 8080 9229)

for port in "${PORTS[@]}"; do
    if ! netstat -tln | grep -q ":$port "; then
        echo "✅ Port $port is available"
    else
        echo "⚠️ Port $port may be in use"
    fi
done

echo "✅ Post-start setup completed!"
```

### Phase 4: VS Code Configuration

#### 4.1 Create VS Code Settings Template

```json
{
  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll": "explicit",
    "source.organizeImports": "explicit"
  },
  "editor.rulers": [80, 120],
  "editor.wordWrap": "on",

  // Python settings
  "python.defaultInterpreterPath": "/usr/local/bin/python3",
  "python.formatting.provider": "none",
  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  },

  // JavaScript/TypeScript settings
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },

  // JSON settings
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },

  // File associations
  "files.associations": {
    "*.yml": "yaml",
    "*.yaml": "yaml",
    "Dockerfile*": "dockerfile",
    ".env*": "dotenv"
  },

  // Exclusions
  "files.exclude": {
    "**/node_modules": true,
    "**/__pycache__": true,
    "**/venv": true,
    "**/.venv": true
  }
}
```

#### 4.2 Create Tasks Configuration

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Install Dependencies",
      "type": "shell",
      "command": "npm install && pip install -r requirements.txt",
      "group": "build",
      "options": {
        "cwd": "${workspaceFolder}"
      },
      "problemMatcher": [],
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": false
      }
    },
    {
      "label": "Start Development Server",
      "type": "shell",
      "command": "npm run dev",
      "group": "build",
      "isBackground": true,
      "problemMatcher": {
        "owner": "npm",
        "pattern": {
          "regexp": "^.*$"
        },
        "background": {
          "activeOnStart": true,
          "beginsPattern": "^.*Starting.*",
          "endsPattern": "^.*Server.*started.*"
        }
      }
    },
    {
      "label": "Run Tests",
      "type": "shell",
      "command": "npm test",
      "group": {
        "kind": "test",
        "isDefault": true
      },
      "problemMatcher": ["$eslint-stylish"]
    },
    {
      "label": "Validate Codespace Configuration",
      "type": "shell",
      "command": "./scripts/validate-config.sh",
      "group": "test",
      "presentation": {
        "echo": true,
        "reveal": "always",
        "focus": true
      }
    }
  ]
}
```

### Phase 5: Testing & Validation

#### 5.1 Create Validation Script

```bash
#!/bin/bash
# scripts/validate-config.sh

echo "🔍 Validating codespace configuration..."

# Check required files exist
REQUIRED_FILES=(
    ".devcontainer/devcontainer.json"
    ".devcontainer/post-create.sh"
    ".devcontainer/post-start.sh"
    ".vscode/settings.json"
)

for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file exists"
    else
        echo "❌ $file missing"
        exit 1
    fi
done

# Validate JSON files
echo "📄 Validating JSON syntax..."
if jq empty .devcontainer/devcontainer.json 2>/dev/null; then
    echo "✅ devcontainer.json syntax valid"
else
    echo "❌ devcontainer.json syntax invalid"
    exit 1
fi

# Check script permissions
echo "🔧 Checking script permissions..."
if [ -x ".devcontainer/post-create.sh" ]; then
    echo "✅ post-create.sh is executable"
else
    echo "❌ post-create.sh not executable"
    exit 1
fi

echo "🎉 Configuration validation passed!"
```

## Comprehensive Configuration Review Checklist

### Phase 1: Quick Health Check

- [ ] All JSON files pass `jq` validation
- [ ] All shell scripts are executable (`chmod +x`)
- [ ] Required files exist (devcontainer.json, scripts)
- [ ] No forbidden `latest` tags in configurations
- [ ] LTS versions used for all languages and tools

### Phase 2: Deep Configuration Analysis

- [ ] Features vs Dockerfile strategy is appropriate
- [ ] Port forwarding matches application requirements
- [ ] Environment variables are properly set
- [ ] Post-create commands will not fail due to missing tools
- [ ] File associations and exclusions are appropriate

### Phase 3: Security & Performance Review

- [ ] No hardcoded secrets or credentials
- [ ] Non-root user configured (if using Dockerfile)
  - [ ] **CRITICAL**: Check base image for existing users (node:\* has 'node' user with UID/GID 1000)
  - [ ] Use existing user instead of creating conflicting UID/GID
- [ ] Minimal necessary packages installed
- [ ] .dockerignore excludes unnecessary files
- [ ] Resource usage is reasonable (< 2GB image size)

### Phase 4: Compatibility & Integration

- [ ] Multi-platform compatibility (amd64/arm64)
- [ ] Integration with existing CI/CD workflows
- [ ] Dependency version compatibility matrix

## Common Codespace Build Errors & Solutions

### Error Category 1: Command Not Found Errors

#### `npm: command not found`

**Cause**: Node.js feature installed but PATH not refreshed before post-create runs  
**Solution**:

```bash
# In post-create.sh, add:
source ~/.bashrc
# Or use full path: /usr/local/share/nvm/current/bin/npm
```

#### `python3: command not found`

**Cause**: Python feature timing issue or wrong installation path
**Solution**:

```bash
# Check feature installation:
which python3
# Use absolute path: /usr/local/bin/python3
```

### Error Category 2: Permission & Access Errors

#### `EACCES: permission denied`

**Cause**: Running as wrong user or incorrect file permissions
**Solution**:

```dockerfile
RUN addgroup -g 1000 vscode && \
    adduser -D -s /bin/bash -u 1000 -G vscode vscode
USER vscode
```

#### `Cannot write to directory`

**Cause**: Mounted volumes with incorrect ownership
**Solution**:

```bash
# In post-create.sh:
sudo chown -R vscode:vscode /workspace
```

### Error Category 3: Network & Dependency Errors

#### `npm ERR! network timeout`

**Cause**: Network connectivity or npm registry issues
**Solution**:

```bash
# Increase timeout and retry:
npm config set fetch-timeout 300000
npm install --verbose
```

#### `pip install fails with SSL errors`

**Cause**: Certificate or proxy issues  
**Solution**:

```bash
pip3 install --trusted-host pypi.org --trusted-host pypi.python.org --trusted-host files.pythonhosted.org -r requirements.txt
```

### Error Category 4: Resource & Performance Issues

#### `Container build timeout`

**Cause**: Large image or slow network during build
**Solution**:

```json
{
  "build": {
    "dockerfile": "Dockerfile",
    "options": ["--progress=plain", "--no-cache"]
  }
}
```

#### `Out of disk space`

**Cause**: Large dependencies or build artifacts
**Solution**:

```dockerfile
# Clean up in same RUN command:
RUN apt-get update && apt-get install -y packages \
    && apt-get clean && rm -rf /var/lib/apt/lists/*
```

### Error Category 5: Extension & VS Code Issues

#### `Extension failed to activate`

**Cause**: Extension compatibility or dependency issues
**Solution**:

```json
{
  "extensions": ["ms-python.python"]
}
```

#### `Settings not applied`

**Cause**: Settings override conflicts or syntax errors
**Solution**: Validate settings.json with `jq empty .vscode/settings.json`

### Error Category 6: Feature Installation Issues

#### `Feature installation timeout`

**Cause**: Slow network or complex feature dependencies
**Solution**:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "22.9.0",
      "installTools": false // Skip optional tools to speed up
    }
  }
}
```

#### `Feature version conflict`

**Cause**: Multiple features installing different versions of same tool
**Solution**: Use specific versions and avoid overlapping features

### Error Category 7: Multi-Platform Issues

#### `platform linux/amd64 not found`

**Cause**: ARM64 vs AMD64 architecture mismatch
**Solution**:

```dockerfile
FROM --platform=linux/amd64 node:22.20.0-alpine
# Or use multi-platform base images
```

#### `exec format error`

**Cause**: Binary built for wrong architecture
**Solution**: Use universal base images or specify platform explicitly

### Error Category 8: Git & SSH Issues

#### `git clone failed: Authentication failed`

**Cause**: SSH keys or credentials not available in container
**Solution**:

```json
{
  "features": {
    "ghcr.io/devcontainers/features/github-cli:1": {},
    "ghcr.io/devcontainers/features/git:1": {
      "version": "latest"
    }
  },
  "mounts": [
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind,consistency=cached"
  ]
}
```

### Error Category 9: Database & Service Connection Issues

#### `Connection refused` to database

**Cause**: Database service not started or wrong connection parameters  
**Solution**:

```yaml
# docker-compose.yml
services:
  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_PASSWORD: password
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 5s
      timeout: 5s
      retries: 5
```

### Error Category 10: Image Size & Layer Issues

#### `Image too large` or `Layer cache miss`

**Cause**: Inefficient Dockerfile layering or large dependencies
**Solution**:

```dockerfile
# ❌ WRONG - Creates unnecessary layers
RUN apt-get update
RUN apt-get install -y package1
RUN apt-get install -y package2
RUN apt-get clean

# ✅ CORRECT - Combine commands, minimize layers
RUN apt-get update && apt-get install -y \
    package1 \
    package2 \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Use multi-stage builds for smaller final images
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

FROM node:22-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
```

### Error Category 11: Shell & Command Issues

#### `/bin/bash: not found` or shell script failures

**Cause**: Alpine images use `/bin/sh` not `/bin/bash`
**Solution**:

```dockerfile
# For Alpine images, use sh or install bash
RUN apk add --no-cache bash

# Or modify scripts to use sh
#!/bin/sh
instead of #!/bin/bash

# In devcontainer.json, specify shell
"containerEnv": {
  "SHELL": "/bin/bash"
}
```

#### Script execution permission denied

**Cause**: Scripts not executable or wrong file permissions
**Solution**:

```dockerfile
# Make scripts executable during COPY
COPY --chmod=755 scripts/ /usr/local/bin/

# Or use RUN chmod after COPY
COPY scripts/ /usr/local/bin/
RUN chmod +x /usr/local/bin/*
```

#### `Port already in use`

**Cause**: Multiple services trying to use same port
**Solution**: Use unique ports and check with `netstat -tlnp`

## Core Principles

1. **Immutable Base Images**: Always use specific version tags, never `latest`
2. **Long-Term Support Priority**: Always choose LTS/stable versions over latest releases
3. **Minimal Surface Area**: Only include what's absolutely necessary
4. **Fail Fast**: Validate early in the build process
5. **Single Source of Truth**: Each configuration aspect should be defined in exactly one place
6. **Deterministic Builds**: Identical inputs must produce identical outputs
7. **Stability Over Features**: Prioritize proven, stable versions over bleeding-edge releases

## Long-Term Support (LTS) Version Strategy

### CRITICAL: Always Use Stable/LTS Versions

For maximum stability and minimal maintenance overhead, **ALWAYS** choose Long-Term Support (LTS) or stable versions over latest releases. This principle applies to:

#### Base Images (MANDATORY LTS VERSIONS)

```dockerfile
# ✅ CORRECT - Use specific LTS versions
FROM node:22.20.0-alpine3.20      # Node.js 22.x LTS with Alpine 3.20 LTS
FROM python:3.11.9-slim-bookworm   # Python 3.11.x LTS with Debian 12 LTS
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04  # Ubuntu 22.04 LTS

# ❌ WRONG - Avoid latest or non-LTS versions
FROM node:latest                   # Unpredictable, breaks without warning
FROM node:21-alpine               # Non-LTS, short support lifecycle
FROM python:3.12-slim            # Too new, potential compatibility issues
FROM ubuntu:23.10                # Non-LTS, 9-month support only
```

#### Programming Language Versions

```json
// devcontainer.json - Use LTS versions
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "22.9.0", // Node.js 22.x LTS (recommended)
      "nodeGypDependencies": true
    },
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.11.9" // Python 3.11.x LTS (supported until 2027-10)
    }
  }
}
```

#### Package Manager Versions

```dockerfile
# Pin to stable versions, not latest
RUN npm install -g npm@10.8.2     # npm LTS version
RUN pip install --upgrade pip==24.2  # Stable pip version
```

#### OS Package Versions

```dockerfile
# Alpine packages - pin to stable versions
RUN apk add --no-cache \
    git=2.43.0-r0 \
    curl=8.5.0-r0 \
    bash=5.2.21-r0

# Ubuntu/Debian packages - use apt pins for stability
RUN apt-get update && apt-get install -y \
    git=1:2.34.1-1ubuntu1.10 \
    curl=7.81.0-1ubuntu1.16 \
    && rm -rf /var/lib/apt/lists/*
```

### LTS Version Reference Table

| Technology  | Current LTS   | Support Until | Recommended Version |
| ----------- | ------------- | ------------- | ------------------- |
| **Node.js** | 22.x          | October 2027  | `22.9.0`            |
| **Node.js** | 20.x          | April 2026    | `20.17.0`           |
| **Python**  | 3.11.x        | October 2027  | `3.11.9`            |
| **Python**  | 3.12.x        | October 2028  | `3.12.5`            |
| **Ubuntu**  | 22.04 LTS     | April 2027    | `ubuntu:22.04`      |
| **Alpine**  | 3.20 LTS      | April 2026    | `alpine:3.20`       |
| **Debian**  | 12 (Bookworm) | 2028          | `debian:12-slim`    |
| **npm**     | 10.x          | Active        | `10.8.2`            |
| **Docker**  | 24.x          | 18 months     | `24.0`              |

### Container Registry Strategy

```dockerfile
# ✅ Use official, maintained registries with LTS images
FROM mcr.microsoft.com/devcontainers/python:1-3.11-bookworm  # Microsoft maintained
FROM docker.io/library/node:22-alpine                        # Docker Official Images
FROM registry.access.redhat.com/ubi8/ubi:8.9                # Red Hat UBI LTS

# ❌ Avoid unmaintained or community-only images
FROM some-user/custom-python:latest    # Unmaintained, unpredictable updates
FROM cool-project/dev-image:bleeding   # Experimental, likely to break
```

### Dependency Pinning Strategy

```json
// package.json - Pin to stable versions
{
  "engines": {
    "node": ">=18.20.0 <19.0.0", // LTS range only
    "npm": ">=10.0.0 <11.0.0" // Stable npm range
  },
  "dependencies": {
    "express": "4.19.2", // Pinned stable version
    "lodash": "4.17.21" // Pinned stable version
  },
  "devDependencies": {
    "eslint": "8.57.0", // Pinned stable version
    "prettier": "3.3.3" // Pinned stable version
  }
}
```

```python
# requirements.txt - Pin to stable versions
Django==4.2.15        # Django 4.2 LTS
psycopg2-binary==2.9.9  # Stable PostgreSQL adapter
requests==2.32.3      # Stable HTTP library
pytest==8.3.2         # Stable testing framework
```

### Update Strategy for LTS Versions

#### Quarterly Review Process

1. **Security Updates**: Apply immediately within same major.minor
2. **Patch Updates**: Apply monthly within same major.minor
3. **Minor Updates**: Evaluate quarterly, test thoroughly
4. **Major Updates**: Annual review, full testing cycle

#### Version Update Examples

```bash
# ✅ Safe updates (same major.minor)
FROM python:3.13.7-slim  →  FROM python:3.13.8-slim
FROM node:22.9.0-alpine   →  FROM node:22.9.1-alpine

# ⚠️ Careful evaluation needed
FROM python:3.12.7-slim  →  FROM python:3.13.7-slim
FROM node:20.17.0-alpine  →  FROM node:22.9.0-alpine

# ❌ High risk, requires extensive testing
FROM python:3.11.9-slim  →  FROM python:3.13.7-slim
FROM node:22.9.0-alpine   →  FROM node:24.5.0-alpine
```

### Critical LTS Rules

1. **NEVER use `latest` tags** - They break without warning
2. **Pin to specific patch versions** - `3.11.9`, not `3.11` or `3`
3. **Choose LTS over non-LTS** - Even if non-LTS has newer features
4. **Document version choices** - Include rationale in comments
5. **Test before updating** - Even patch version updates
6. **Monitor EOL dates** - Plan migrations before support ends
7. **Use official sources** - Prefer vendor-maintained images
8. **Batch related updates** - Update related components together

### Version Validation Commands

```bash
# Verify LTS status before using
node --version    # Should show LTS version (22.x)
python --version  # Should show stable version (3.11.x or 3.12.x)

# Check image tags for LTS indicators
docker pull node:22-alpine && docker inspect node:22-alpine | grep -i lts
docker pull python:3.11-slim && docker inspect python:3.11-slim | grep -i version

# Validate dependency versions
npm ls --depth=0  # Check for pinned versions
pip freeze | grep -E "Django|requests|pytest"  # Verify Python packages
```

## .devcontainer Configuration Rules

### File Structure (MANDATORY)

```
.devcontainer/
├── devcontainer.json          # Main configuration
├── Dockerfile                 # Container definition
└── docker-compose.yml         # Optional: for multi-service setups
```

### devcontainer.json Best Practices

#### Base Structure

```json
{
  "name": "Project Name",
  "dockerFile": "Dockerfile",
  "context": ".",
  "shutdownAction": "stopCompose",
  "updateContentCommand": "echo 'Container updated'",
  "postCreateCommand": ".devcontainer/post-create.sh",
  "postStartCommand": ".devcontainer/post-start.sh"
}
```

#### Port Configuration

```json
{
  "forwardPorts": [3000, 8080, 9229],
  "portsAttributes": {
    "3000": {
      "label": "Application",
      "onAutoForward": "notify"
    },
    "9229": {
      "label": "Debug",
      "onAutoForward": "silent"
    }
  }
}
```

#### Environment Variables

```json
{
  "remoteEnv": {
    "NODE_ENV": "development",
    "PYTHONPATH": "/workspace",
    "PATH": "${containerEnv:PATH}:/workspace/scripts"
  }
}
```

#### Features Configuration

```json
{
  "features": {
    "ghcr.io/devcontainers/features/node:1": {
      "version": "22.9.0", // Node.js 22.x LTS - pin to specific version
      "nodeGypDependencies": true
    },
    "ghcr.io/devcontainers/features/python:1": {
      "version": "3.11.9" // Python 3.11.x LTS - pin to specific version
    },
    "ghcr.io/devcontainers/features/docker-outside-of-docker:1": {},
    "ghcr.io/devcontainers/features/github-cli:1": {}
  }
}
```

#### VS Code Customizations

```json
{
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-python.pylance",
        "ms-python.black-formatter",
        "esbenp.prettier-vscode",
        "dbaeumer.vscode-eslint",
        "GitHub.copilot",
        "GitHub.copilot-chat"
      ],
      "settings": {
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
          "source.fixAll": "explicit"
        }
      }
    }
  }
}
```

### Critical Rules for devcontainer.json

1. **Never use relative paths** outside the `.devcontainer` folder
2. **Always specify exact versions** for features and base images
3. **Include health checks** via `postCreateCommand`
4. **Set explicit timeouts** for long-running commands
5. **Use `updateContentCommand`** for dependency updates

## Dockerfile Best Practices

### Multi-Stage Build Template

```dockerfile
# Stage 1: Base dependencies
FROM node:22.9.0-alpine3.20 AS base    # LTS versions pinned
WORKDIR /workspace
RUN apk add --no-cache \
    git=2.43.0-r0 \
    python3=3.11.9-r1 \
    py3-pip=23.3.1-r0 \
    build-base=0.5-r3 \
    && npm install -g npm@10.8.2

# Stage 2: Development dependencies
FROM base AS development
COPY package*.json ./
RUN npm ci --only=production && npm ci --only=development
COPY requirements.txt ./
RUN pip3 install --no-cache-dir -r requirements.txt

# Stage 3: Final development image
FROM development AS final
COPY . .
RUN npm run build:dev || true
EXPOSE 3000 8080 9229
CMD ["npm", "run", "dev"]
```

### Critical Dockerfile Rules

1. **Use specific LTS base image versions**: `node:22.9.0-alpine3.20` (LTS), not `node:latest` or non-LTS versions
2. **Combine RUN commands**: Reduce layer count and image size
3. **Install system dependencies first**: Before language-specific packages
4. **Use `.dockerignore`**: Exclude unnecessary files
5. **Set proper USER**: Don't run as root in final stage
6. **Include health checks**: `HEALTHCHECK` directive
7. **Use multi-stage builds**: Separate build and runtime environments

### .dockerignore Template

```
node_modules/
npm-debug.log*
.npm
.nyc_output
coverage/
.git/
.gitignore
README.md
.env
.env.local
.env.development.local
.env.test.local
.env.production.local
**/__pycache__/
**/*.pyc
.pytest_cache/
.coverage
.vscode/
.devcontainer/
```

## .vscode Configuration Rules

### Folder Structure (RECOMMENDED)

```
.vscode/
├── settings.json              # Workspace settings
├── tasks.json                 # Build/test tasks
├── launch.json                # Debug configurations
├── extensions.json            # Recommended extensions
└── c_cpp_properties.json      # Optional: C/C++ specific
```

### settings.json Best Practices

```json
{
  "python.defaultInterpreterPath": "/usr/local/bin/python3",
  "python.formatting.provider": "none",
  "python.linting.enabled": true,
  "python.linting.pylintEnabled": false,
  "python.linting.flake8Enabled": true,
  "python.linting.flake8Args": ["--max-line-length=88"],

  "eslint.workingDirectories": ["./"],
  "eslint.validate": ["javascript", "typescript"],

  "editor.formatOnSave": true,
  "editor.codeActionsOnSave": {
    "source.fixAll.eslint": "explicit",
    "source.organizeImports": "explicit"
  },

  "[python]": {
    "editor.defaultFormatter": "ms-python.black-formatter"
  },
  "[javascript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[json]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },

  "files.exclude": {
    "**/node_modules": true,
    "**/__pycache__": true,
    "**/.pytest_cache": true,
    "**/coverage": true
  },

  "search.exclude": {
    "**/node_modules": true,
    "**/coverage": true
  }
}
```

### tasks.json Template

```json
{
  "version": "2.0.0",
  "tasks": [
    {
      "label": "Install Dependencies",
      "type": "shell",
      "command": "npm install && pip install -r requirements.txt",
      "group": "build",
      "options": {
        "cwd": "${workspaceFolder}"
      },
      "problemMatcher": []
    },
    {
      "label": "Run Tests",
      "type": "shell",
      "command": "npm test",
      "group": {
        "kind": "test",
        "isDefault": true
      },
      "problemMatcher": ["$eslint-stylish"]
    },
    {
      "label": "Start Development Server",
      "type": "shell",
      "command": "npm run dev",
      "group": "build",
      "isBackground": true,
      "problemMatcher": {
        "owner": "npm",
        "pattern": {
          "regexp": "^.*$"
        },
        "background": {
          "activeOnStart": true,
          "beginsPattern": "^.*Starting development server.*$",
          "endsPattern": "^.*Server started on.*$"
        }
      }
    }
  ]
}
```

### launch.json Template

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Debug Node.js App",
      "type": "node",
      "request": "launch",
      "program": "${workspaceFolder}/src/index.js",
      "console": "integratedTerminal",
      "env": {
        "NODE_ENV": "development"
      },
      "skipFiles": ["<node_internals>/**"]
    },
    {
      "name": "Debug Python Script",
      "type": "python",
      "request": "launch",
      "program": "${workspaceFolder}/python/main.py",
      "console": "integratedTerminal",
      "cwd": "${workspaceFolder}"
    },
    {
      "name": "Attach to Running Process",
      "type": "node",
      "request": "attach",
      "port": 9229,
      "skipFiles": ["<node_internals>/**"]
    }
  ]
}
```

## Docker Compose Best Practices

### Basic Structure

```yaml
version: "3.8"

services:
  app:
    build:
      context: .
      dockerfile: .devcontainer/Dockerfile
      target: development
    ports:
      - "3000:3000"
      - "9229:9229"
    volumes:
      - .:/workspace:cached
      - /workspace/node_modules
      - /workspace/.venv
    environment:
      - NODE_ENV=development
      - PYTHONPATH=/workspace
    depends_on:
      - db
      - redis
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

  db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: appdb
      POSTGRES_USER: appuser
      POSTGRES_PASSWORD: apppass
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

volumes:
  postgres_data:
```

## Troubleshooting Guide

### Common Build Failure Patterns

#### 1. User/Group Already Exists Errors

**Symptom**: `groupadd: GID '1000' already exists` or `useradd: UID 1000 is not unique`
**Cause**: Base image (like node:20) already has user with same UID/GID
**Solution**: Use existing user from base image instead of creating new one

```dockerfile
# ❌ WRONG - Don't create conflicting users
RUN groupadd -r -g 1000 appuser && \
    useradd -r -g appuser -u 1000 appuser

# ✅ CORRECT - Use existing user from base image
# For node:* images, use existing 'node' user
RUN mkdir -p /app/reports /app/results && \
    chown -R node:node /app && \
    echo "node ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/node && \
    chmod 0440 /etc/sudoers.d/node
USER node

# For ubuntu/debian images, create user only if not exists
RUN if ! id -u appuser > /dev/null 2>&1; then \
        groupadd -r -g 1000 appuser && \
        useradd -r -g appuser -u 1000 -s /bin/bash appuser; \
    fi
USER appuser
```

#### 2. Permission Errors

**Symptom**: `EACCES: permission denied`
**Solution**:

```dockerfile
RUN addgroup -g 1000 appgroup && \
    adduser -D -s /bin/bash -u 1000 -G appgroup appuser
USER appuser
```

#### 2. Package Installation Failures

**Symptom**: `npm ERR!` or `pip install failed`
**Solution**:

```dockerfile
# Clear package caches
RUN npm cache clean --force
RUN pip cache purge

# Use specific package versions
COPY package-lock.json requirements.txt ./
RUN npm ci --only=production
RUN pip install --no-cache-dir -r requirements.txt
```

#### 3. Port Conflicts

**Symptom**: `Port already in use`
**Solution**:

```json
{
  "forwardPorts": [3000, 8080],
  "portsAttributes": {
    "3000": {
      "onAutoForward": "ignore"
    }
  }
}
```

#### 4. Extension Loading Issues

**Symptom**: Extensions not installing
**Solution**:

```json
{
  "customizations": {
    "vscode": {
      "extensions": ["ms-python.python"]
    }
  }
}
```

#### 5. Container Exit Code Failures

**Symptom**: Container exits with codes 125, 126, 127
**Cause**:

- 125: Docker daemon error or container runtime issue
- 126: Container command not executable
- 127: Container command not found
  **Solution**:

```bash
# For exit code 126 - make scripts executable
COPY --chmod=755 entrypoint.sh /entrypoint.sh

# For exit code 127 - check command paths
RUN which node && which npm  # Verify commands exist
CMD ["/usr/local/bin/node", "server.js"]  # Use full path
```

#### 6. Build Context & Performance Issues

**Symptom**: "Build context too large" or "no space left on device"
**Cause**: Including unnecessary files in Docker build context
**Solution**:

```dockerfile
# .dockerignore
node_modules
.git
.vscode
*.log
README.md
.env*
```

#### 7. Health Check Failures

**Symptom**: Container starts but health check fails
**Cause**: Health check command doesn't work or service not ready
**Solution**:

```dockerfile
# Simple health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD node -e "console.log('Health check passed')" || exit 1

# Service-specific health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

#### 8. Environment Variable Issues

**Symptom**: "Environment variable not set" or wrong paths
**Cause**: Variables not properly defined or shell not loading them
**Solution**:

```json
{
  "remoteEnv": {
    "NODE_ENV": "development",
    "PYTHONPATH": "${containerWorkspaceFolder}:${containerWorkspaceFolder}/src",
    "PATH": "${containerWorkspaceFolder}/node_modules/.bin:${containerEnv:PATH}"
  },
  "containerEnv": {
    "TZ": "UTC"
  }
}
```

#### 9. File System Mount Issues

**Symptom**: "File not found" or "Permission denied" on mounted files
**Cause**: Volume mount problems or file system differences
**Solution**:

```json
{
  "mounts": [
    "source=${localWorkspaceFolder}/.env,target=${containerWorkspaceFolder}/.env,type=bind,consistency=cached",
    "source=${localEnv:HOME}/.ssh,target=/home/vscode/.ssh,type=bind,consistency=cached"
  ],
  "postCreateCommand": "sudo chown -R vscode:vscode ${containerWorkspaceFolder}"
}
```

#### 10. Memory & Resource Limit Issues

**Symptom**: "Killed" or "Out of memory" during build/runtime
**Cause**: Container resource limits too low
**Solution**:

```json
{
  "runArgs": ["--memory=4g", "--memory-swap=4g", "--cpus=2"],
  "hostRequirements": {
    "memory": "4gb",
    "cpus": 2
  }
}
```

### Emergency Recovery Steps

1. **Complete Rebuild**:

   ```bash
   docker system prune -af
   docker volume prune -f
   ```

2. **Reset Codespace**:
   - Delete `.devcontainer` folder
   - Recreate from template
   - Force rebuild container

3. **Validate Configuration**:

   ```bash
   # Test Dockerfile
   docker build -t test-build .devcontainer/

   # Validate JSON
   cat .devcontainer/devcontainer.json | jq '.'

   # Check ports
   netstat -tlnp
   ```

### Advanced Troubleshooting Patterns

#### Network & Proxy Issues

**Symptoms**: SSL certificate errors, connection timeouts, proxy blocks
**Solutions**:

```dockerfile
# Handle corporate proxies
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
ENV NO_PROXY=${NO_PROXY}

# Skip SSL verification (development only!)
RUN npm config set strict-ssl false
RUN pip config set global.trusted-host "pypi.org files.pythonhosted.org pypi.python.org"
```

#### Cache & Dependency Issues

**Symptoms**: Stale dependencies, cache conflicts, version mismatches
**Solutions**:

```bash
# Clear all caches
npm cache clean --force
pip cache purge
docker builder prune -af

# Force fresh install
rm -rf node_modules package-lock.json
npm install

# Lock dependency versions
npm ci --ignore-scripts  # Skip potentially problematic scripts
pip install --no-deps -r requirements.txt  # Skip dependency resolution
```

#### Multi-Architecture Problems

**Symptoms**: `exec format error`, platform-specific build failures
**Solutions**:

```dockerfile
# Force specific platform
FROM --platform=linux/amd64 node:22-alpine

# Multi-architecture build
FROM node:22-alpine
RUN if [ "$(uname -m)" = "aarch64" ]; then \
      # ARM64-specific commands; \
    else \
      # AMD64-specific commands; \
    fi
```

#### Signal & Process Management

**Symptoms**: Zombie processes, signal handling issues, graceful shutdown problems
**Solutions**:

```dockerfile
# Use tini for proper signal handling
RUN apk add --no-cache tini
ENTRYPOINT ["/sbin/tini", "--"]

# Or use Node.js 22+ built-in signal handling
CMD ["node", "--enable-source-maps", "server.js"]

# Handle graceful shutdown in app
process.on('SIGTERM', () => {
  server.close(() => process.exit(0));
});
```

## Validation Checklist

### Pre-Commit Checklist

- [ ] Dockerfile builds successfully locally
- [ ] All JSON files are valid (use `jq` to validate)
- [ ] Port numbers don't conflict
- [ ] All referenced files exist
- [ ] Dependencies have explicit versions
- [ ] Health checks pass

### Post-Create Validation

- [ ] All extensions installed
- [ ] Formatters working
- [ ] Linters running
- [ ] Debug configurations functional
- [ ] Tasks execute successfully

### Performance Checklist

- [ ] Image size < 2GB
- [ ] Build time < 5 minutes
- [ ] Container starts in < 30 seconds
- [ ] Extensions load in < 1 minute

## Quick Diagnostic Commands

### Immediate Health Check (Run First)

```bash
# Quick validation of critical components
echo "🏥 Quick Codespace Health Check"
echo "==============================="

# 1. JSON Syntax Check
jq empty .devcontainer/devcontainer.json && echo "✅ devcontainer.json OK" || echo "❌ devcontainer.json INVALID"
jq empty .vscode/settings.json && echo "✅ settings.json OK" || echo "❌ settings.json INVALID"
jq empty package.json && echo "✅ package.json OK" || echo "❌ package.json INVALID"

# 2. Command Availability
echo -e "\n🔧 Command Availability:"
command -v node && echo "✅ Node.js: $(node --version)" || echo "❌ Node.js missing"
command -v npm && echo "✅ npm: $(npm --version)" || echo "❌ npm missing"
command -v python3 && echo "✅ Python: $(python3 --version)" || echo "❌ Python missing"
command -v pip3 && echo "✅ pip3: $(pip3 --version)" || echo "❌ pip3 missing"

# 3. Script Permissions
echo -e "\n📜 Script Permissions:"
[ -x ".devcontainer/post-create.sh" ] && echo "✅ post-create.sh executable" || echo "❌ post-create.sh not executable"
[ -x ".devcontainer/post-start.sh" ] && echo "✅ post-start.sh executable" || echo "❌ post-start.sh not executable"

# 4. Port Availability
echo -e "\n🔌 Port Check:"
netstat -tln 2>/dev/null | grep -E ":(3000|8080|9229)" && echo "⚠️  Some ports in use" || echo "✅ Ports available"

echo -e "\n🏁 Health check complete!"
```

### Post-Create Failure Diagnosis

```bash
# Run this if post-create command fails
echo "🔍 Post-Create Failure Diagnosis"
echo "================================"

# Check if post-create script has issues
if [ -f ".devcontainer/devcontainer.json" ]; then
    POST_CREATE=$(jq -r '.postCreateCommand // empty' .devcontainer/devcontainer.json)
    echo "📋 Post-create command: $POST_CREATE"

    if [ -n "$POST_CREATE" ] && [[ "$POST_CREATE" =~ \.sh$ ]]; then
        echo "🧪 Testing script syntax..."
        bash -n "$POST_CREATE" && echo "✅ Syntax OK" || echo "❌ Syntax errors found"

        echo "🔍 Checking for missing commands in script..."
        grep -oE '\b(npm|node|pip3|python3|git|curl|wget)\b' "$POST_CREATE" | sort -u | while read cmd; do
            if command -v "$cmd" >/dev/null 2>&1; then
                echo "✅ $cmd available"
            else
                echo "❌ $cmd missing - will cause script failure"
            fi
        done
    fi
else
    echo "❌ No devcontainer.json found"
fi
```

## Pre-Testing Validation Commands

### MANDATORY: Run Before Every Test/Deployment

Before approving any changes for testing, execute these validation commands to catch errors early:

### Level 1: Quick Syntax Validation (30 seconds)

```bash
#!/bin/bash
# Quick validation for immediate feedback

echo "⚡ Quick Syntax Check (Level 1)"
echo "==============================="

ERRORS=0

# JSON validation
for file in .devcontainer/devcontainer.json .vscode/settings.json .vscode/tasks.json .vscode/launch.json package.json; do
    if [ -f "$file" ]; then
        if jq empty "$file" 2>/dev/null; then
            echo "✅ $file"
        else
            echo "❌ $file - JSON syntax error"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

# YAML validation (if exists)
for file in docker-compose.yml .github/workflows/*.yml; do
    if [ -f "$file" ]; then
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo "✅ $file"
        else
            echo "❌ $file - YAML syntax error"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

# Script permissions
for script in .devcontainer/*.sh scripts/*.sh; do
    if [ -f "$script" ]; then
        if [ -x "$script" ]; then
            echo "✅ $script (executable)"
        else
            echo "❌ $script (not executable)"
            ERRORS=$((ERRORS + 1))
        fi
    fi
done

if [ $ERRORS -eq 0 ]; then
    echo "🎉 Level 1 validation passed!"
    exit 0
else
    echo "💥 $ERRORS errors found in Level 1 validation"
    exit 1
fi
```

### Level 2: Environment & Dependency Validation (2 minutes)

```bash
#!/bin/bash
# Comprehensive environment validation

echo "🔬 Environment Validation (Level 2)"
echo "===================================="

ERRORS=0
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Post-create command validation
validate_post_create() {
    echo -e "\n🔧 Validating post-create commands..."

    if [ -f ".devcontainer/devcontainer.json" ]; then
        POST_CREATE=$(jq -r '.postCreateCommand // empty' .devcontainer/devcontainer.json 2>/dev/null)

        if [ -n "$POST_CREATE" ]; then
            echo "Found: $POST_CREATE"

            # If it's a shell script, validate it
            if [[ "$POST_CREATE" =~ \.sh$ ]] && [ -f "$POST_CREATE" ]; then
                # Syntax check
                if bash -n "$POST_CREATE" 2>/dev/null; then
                    echo -e "${GREEN}✅${NC} Script syntax valid"
                else
                    echo -e "${RED}❌${NC} Script syntax errors"
                    ERRORS=$((ERRORS + 1))
                fi

                # Command availability check
                COMMANDS=$(grep -oE '\b(npm|node|pip3|python3|git|curl|wget)\b' "$POST_CREATE" 2>/dev/null | sort -u)
                for cmd in $COMMANDS; do
                    if command -v "$cmd" >/dev/null 2>&1; then
                        echo -e "${GREEN}✅${NC} $cmd available"
                    else
                        echo -e "${RED}❌${NC} $cmd missing (post-create will fail)"
                        ERRORS=$((ERRORS + 1))
                    fi
                done
            fi
        fi
    fi
}

# LTS version validation
validate_lts_versions() {
    echo -e "\n🔒 Validating LTS versions..."

    # Check for 'latest' tags (forbidden)
    LATEST_USAGE=$(grep -r ":latest" . --include="Dockerfile*" --include="*.json" --include="*.yml" --exclude-dir=node_modules 2>/dev/null || true)
    if [ -n "$LATEST_USAGE" ]; then
        echo -e "${RED}❌${NC} Found forbidden 'latest' tags:"
        echo "$LATEST_USAGE"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✅${NC} No 'latest' tags found"
    fi

    # Check Node.js versions
    if [ -f ".devcontainer/devcontainer.json" ]; then
        NODE_VERSION=$(jq -r '.features."ghcr.io/devcontainers/features/node:1".version // empty' .devcontainer/devcontainer.json 2>/dev/null)
        if [ -n "$NODE_VERSION" ]; then
            MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
      if [ "$MAJOR" = "20" ] || [ "$MAJOR" = "22" ]; then
                echo -e "${GREEN}✅${NC} Node.js $NODE_VERSION is LTS"
            else
                echo -e "${RED}❌${NC} Node.js $NODE_VERSION is not LTS"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    fi
}

# Feature timing validation
validate_timing() {
    echo -e "\n⏰ Validating command timing..."

    if [ -f ".devcontainer/devcontainer.json" ]; then
        POST_CREATE=$(jq -r '.postCreateCommand // empty' .devcontainer/devcontainer.json 2>/dev/null)
        HAS_NODE=$(jq -r '.features | has("ghcr.io/devcontainers/features/node:1")' .devcontainer/devcontainer.json 2>/dev/null)

        if [ "$HAS_NODE" = "true" ] && echo "$POST_CREATE" | grep -q npm; then
            echo -e "${RED}❌${NC} High risk: npm in postCreateCommand with Node.js feature"
            echo -e "${YELLOW}💡${NC} Solution: Use 'source ~/.bashrc && npm install'"
            ERRORS=$((ERRORS + 1))
        fi
    fi
}

# Run validations
validate_post_create
validate_lts_versions
validate_timing

# Final result
if [ $ERRORS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 Level 2 validation passed!${NC}"
    exit 0
else
    echo -e "\n${RED}💥 $ERRORS errors found in Level 2 validation${NC}"
    exit 1
fi
```

### Level 3: Full Comprehensive Validation (5 minutes)

````bash

#### JSON File Validation
```bash
# Validate all JSON files in the project
find . -name "*.json" -not -path "./node_modules/*" -not -path "./.git/*" | while read file; do
  echo "Validating: $file"
  jq empty "$file" || echo "❌ INVALID JSON: $file"
done

# Quick validation of specific config files
jq empty .devcontainer/devcontainer.json && echo "✅ devcontainer.json valid" || echo "❌ devcontainer.json INVALID"
jq empty .vscode/settings.json && echo "✅ settings.json valid" || echo "❌ settings.json INVALID"
jq empty .vscode/tasks.json && echo "✅ tasks.json valid" || echo "❌ tasks.json INVALID"
jq empty .vscode/launch.json && echo "✅ launch.json valid" || echo "❌ launch.json INVALID"
jq empty package.json && echo "✅ package.json valid" || echo "❌ package.json INVALID"
````

#### YAML File Validation

```bash
# Validate all YAML files
find . -name "*.yml" -o -name "*.yaml" -not -path "./node_modules/*" -not -path "./.git/*" | while read file; do
  echo "Validating: $file"
  python3 -c "import yaml; yaml.safe_load(open('$file'))" && echo "✅ $file valid" || echo "❌ INVALID YAML: $file"
done

# Alternative using yq (if available)
find . -name "*.yml" -o -name "*.yaml" -not -path "./node_modules/*" | while read file; do
  yq eval '.' "$file" > /dev/null && echo "✅ $file valid" || echo "❌ INVALID YAML: $file"
done

# Specific validation for common files
if [ -f "docker-compose.yml" ]; then
  docker-compose config > /dev/null && echo "✅ docker-compose.yml valid" || echo "❌ docker-compose.yml INVALID"
fi
```

#### Dockerfile Validation

```bash
# Validate Dockerfile syntax
if [ -f "Dockerfile" ]; then
  docker build --no-cache --dry-run . > /dev/null && echo "✅ Dockerfile syntax valid" || echo "❌ Dockerfile INVALID"
fi

if [ -f ".devcontainer/Dockerfile" ]; then
  docker build --no-cache --dry-run -f .devcontainer/Dockerfile . > /dev/null && echo "✅ .devcontainer/Dockerfile syntax valid" || echo "❌ .devcontainer/Dockerfile INVALID"
fi

# Advanced Dockerfile linting (if hadolint is available)
if command -v hadolint >/dev/null 2>&1; then
  find . -name "Dockerfile*" | while read file; do
    hadolint "$file" && echo "✅ $file passes linting" || echo "❌ $file has linting issues"
  done
fi
```

#### Post-Create Command Validation

````bash
# CRITICAL: Test post-create commands to catch 'command not found' errors
validate_post_create_commands() {
    echo -e "\n🔧 Validating post-create commands..."

    # Check if post-create command exists and is executable
    if [ -f ".devcontainer/devcontainer.json" ]; then
        post_create_cmd=$(jq -r '.postCreateCommand // empty' .devcontainer/devcontainer.json 2>/dev/null)
        if [ -n "$post_create_cmd" ]; then
            echo "Found post-create command: $post_create_cmd"

            # If it's a shell script, check if it exists and is executable
            if [[ "$post_create_cmd" =~ \.sh$ ]] && [ -f "$post_create_cmd" ]; then
                if [ -x "$post_create_cmd" ]; then
                    echo -e "${GREEN}✅${NC} Post-create script is executable: $post_create_cmd"
                else
                    echo -e "${RED}❌${NC} Post-create script not executable: $post_create_cmd"
                    ERRORS=$((ERRORS + 1))
                fi
            fi

            # Test command availability that post-create might use
            echo "Checking command availability for post-create script..."

            # Check for common commands used in post-create
            commands_to_check=("npm" "node" "python3" "pip3" "git" "curl" "wget")
            for cmd in "${commands_to_check[@]}"; do
                if grep -q "$cmd" "$post_create_cmd" 2>/dev/null; then
                    if command -v "$cmd" >/dev/null 2>&1; then
                        echo -e "${GREEN}✅${NC} Required command available: $cmd"
                    else
                        echo -e "${RED}❌${NC} Required command NOT found: $cmd (will cause post-create failure)"
                        ERRORS=$((ERRORS + 1))
                    fi
                fi
            done
        fi
    fi
}

# Test environment variables and PATH
validate_environment() {
    echo -e "\n🌍 Validating environment setup..."

    # Check NODE_PATH and npm availability
    if command -v node >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} Node.js available: $(node --version)"

        if command -v npm >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} npm available: $(npm --version)"
        else
            echo -e "${RED}❌${NC} npm not found (Node.js installed but npm missing)"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "${YELLOW}⚠️${NC} Node.js not found (may be installed by features later)"
    fi

    # Check Python and pip availability
    if command -v python3 >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} Python available: $(python3 --version)"

        if command -v pip3 >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} pip3 available: $(pip3 --version)"
        else
            echo -e "${RED}❌${NC} pip3 not found (Python installed but pip missing)"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "${YELLOW}⚠️${NC} Python not found (may be installed by features later)"
    fi

    # Check PATH includes common directories
    echo "Checking PATH configuration..."
    if echo "$PATH" | grep -q "/usr/local/bin"; then
        echo -e "${GREEN}✅${NC} /usr/local/bin in PATH"
    else
        echo -e "${YELLOW}⚠️${NC} /usr/local/bin not in PATH"
    fi

    # Check for devcontainer features PATH issues
    if [ -f ".devcontainer/devcontainer.json" ]; then
        has_node_feature=$(jq -r '.features | has("ghcr.io/devcontainers/features/node:1")' .devcontainer/devcontainer.json 2>/dev/null)
        if [ "$has_node_feature" = "true" ] && ! command -v npm >/dev/null 2>&1; then
            echo -e "${RED}❌${NC} Node.js feature configured but npm not available (PATH/timing issue)"
            echo -e "${YELLOW}💡${NC} This will cause post-create 'npm: command not found' errors"
            ERRORS=$((ERRORS + 1))
        fi

        has_python_feature=$(jq -r '.features | has("ghcr.io/devcontainers/features/python:1")' .devcontainer/devcontainer.json 2>/dev/null)
        if [ "$has_python_feature" = "true" ] && ! command -v pip3 >/dev/null 2>&1; then
            echo -e "${RED}❌${NC} Python feature configured but pip3 not available (PATH/timing issue)"
            ERRORS=$((ERRORS + 1))
        fi
    fi
}

# Simulate post-create command execution (dry-run)
validate_post_create_dry_run() {
    echo -e "\n🧪 Testing post-create command execution (dry-run)..."

    if [ -f ".devcontainer/devcontainer.json" ]; then
        post_create_cmd=$(jq -r '.postCreateCommand // empty' .devcontainer/devcontainer.json 2>/dev/null)
        if [ -n "$post_create_cmd" ]; then
            echo "Attempting dry-run of: $post_create_cmd"

            # If it's a shell script, try to validate it
            if [[ "$post_create_cmd" =~ \.sh$ ]] && [ -f "$post_create_cmd" ]; then
                echo "Syntax checking shell script: $post_create_cmd"
                if bash -n "$post_create_cmd" 2>/dev/null; then
                    echo -e "${GREEN}✅${NC} Shell script syntax valid"
                else
                    echo -e "${RED}❌${NC} Shell script syntax errors found"
                    ERRORS=$((ERRORS + 1))
                fi

                # Check for commands that might not be available
                missing_commands=$(grep -oE '\b(npm|node|pip3|python3|git|curl|wget)\b' "$post_create_cmd" 2>/dev/null | sort -u)
                for cmd in $missing_commands; do
                    if ! command -v "$cmd" >/dev/null 2>&1; then
                        echo -e "${RED}❌${NC} Command '$cmd' used in post-create but not available"
                        ERRORS=$((ERRORS + 1))
                    fi
                done
            fi
        fi
    fi
}

validate_post_create_commands
validate_environment
validate_post_create_dry_run

#### LTS Version Validation
```bash
# Validate all versions are LTS/stable before testing
validate_lts_versions() {
    echo -e "\n🔒 Validating LTS/stable versions..."

    # Check Node.js versions for LTS
    find . -name "Dockerfile*" | while read dockerfile; do
        node_version=$(grep "FROM node:" "$dockerfile" 2>/dev/null | head -1 | sed 's/.*node:\([^-]*\).*/\1/' || echo "")
    if [ -n "$node_version" ]; then
      major_version=$(echo "$node_version" | cut -d. -f1)
      if [ "$major_version" = "20" ] || [ "$major_version" = "22" ]; then
        echo -e "✅ Node.js $node_version is LTS in $dockerfile"
            else
                echo -e "❌ Node.js $node_version is NOT LTS in $dockerfile"
            fi
        fi
    done

    # Check for 'latest' tags (forbidden)
    latest_usage=$(grep -r ":latest" . --include="Dockerfile*" --include="*.json" --include="*.yml" --exclude-dir=node_modules 2>/dev/null || true)
    if [ -n "$latest_usage" ]; then
        echo -e "❌ Found forbidden 'latest' tags:"
        echo "$latest_usage"
    else
        echo -e "✅ No 'latest' tags found"
    fi
}

validate_lts_versions
````

#### Comprehensive Validation Script

```bash
#!/bin/bash
# save as: scripts/validate-config.sh

set -e

echo "🔍 Starting comprehensive configuration validation..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0

validate_json() {
    echo -e "\n📄 Validating JSON files..."
    find . -name "*.json" -not -path "./node_modules/*" -not -path "./.git/*" -not -path "./coverage/*" | while read file; do
        if jq empty "$file" 2>/dev/null; then
            echo -e "${GREEN}✅${NC} $file"
        else
            echo -e "${RED}❌${NC} $file"
            ERRORS=$((ERRORS + 1))
        fi
    done
}

validate_yaml() {
    echo -e "\n📄 Validating YAML files..."
    find . \( -name "*.yml" -o -name "*.yaml" \) -not -path "./node_modules/*" -not -path "./.git/*" | while read file; do
        if python3 -c "import yaml; yaml.safe_load(open('$file'))" 2>/dev/null; then
            echo -e "${GREEN}✅${NC} $file"
        else
            echo -e "${RED}❌${NC} $file"
            ERRORS=$((ERRORS + 1))
        fi
    done
}

validate_docker() {
    echo -e "\n🐳 Validating Docker files..."
    find . -name "Dockerfile*" -not -path "./node_modules/*" | while read file; do
        if docker build --no-cache --dry-run -f "$file" . >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} $file"
        else
            echo -e "${RED}❌${NC} $file"
            ERRORS=$((ERRORS + 1))
        fi
    done
}

validate_lts_versions() {
    echo -e "\n🔒 Validating LTS/stable versions..."

    # Check Node.js versions for LTS
    find . -name "Dockerfile*" | while read dockerfile; do
        node_version=$(grep "FROM node:" "$dockerfile" 2>/dev/null | head -1 | sed 's/.*node:\([^-]*\).*/\1/' || echo "")
    if [ -n "$node_version" ]; then
      major_version=$(echo "$node_version" | cut -d. -f1)
      if [ "$major_version" = "20" ] || [ "$major_version" = "22" ]; then
        echo -e "${GREEN}✅${NC} Node.js $node_version is LTS in $dockerfile"
            else
                echo -e "${RED}❌${NC} Node.js $node_version is NOT LTS in $dockerfile"
                ERRORS=$((ERRORS + 1))
            fi
        fi
    done

    # Check Python versions for stable releases
    find . -name "Dockerfile*" | while read dockerfile; do
        python_version=$(grep "FROM python:" "$dockerfile" 2>/dev/null | head -1 | sed 's/.*python:\([^-]*\).*/\1/' || echo "")
        if [ -n "$python_version" ]; then
            if echo "$python_version" | grep -qE "^3\.(11|12)"; then
                echo -e "${GREEN}✅${NC} Python $python_version is stable/LTS in $dockerfile"
            else
                echo -e "${YELLOW}⚠️${NC} Python $python_version may not be LTS in $dockerfile"
            fi
        fi
    done

    # Check for 'latest' tags (forbidden)
    latest_usage=$(grep -r ":latest" . --include="Dockerfile*" --include="*.json" --include="*.yml" --exclude-dir=node_modules 2>/dev/null || true)
    if [ -n "$latest_usage" ]; then
        echo -e "${RED}❌${NC} Found forbidden 'latest' tags:"
        echo "$latest_usage"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✅${NC} No 'latest' tags found"
    fi
}

validate_permissions() {
    echo -e "\n🔐 Validating permissions..."

    # Check for world-writable files (security risk)
    world_writable=$(find . -type f -perm -002 -not -path "./node_modules/*" -not -path "./.git/*" 2>/dev/null || true)
    if [ -n "$world_writable" ]; then
        echo -e "${RED}❌${NC} World-writable files found:"
        echo "$world_writable"
        ERRORS=$((ERRORS + 1))
    else
        echo -e "${GREEN}✅${NC} No world-writable files"
    fi

    # Validate Dockerfile USER instructions
    find . -name "Dockerfile*" | while read dockerfile; do
        if grep -q "^USER root" "$dockerfile" 2>/dev/null; then
            echo -e "${RED}❌${NC} Running as root user in $dockerfile"
            ERRORS=$((ERRORS + 1))
        elif grep -q "^USER " "$dockerfile" 2>/dev/null; then
            user=$(grep "^USER " "$dockerfile" | tail -1 | awk '{print $2}')
            echo -e "${GREEN}✅${NC} Using non-root user '$user' in $dockerfile"
        else
            echo -e "${YELLOW}⚠️${NC} No USER specified in $dockerfile (will run as root)"
        fi
    done
}

validate_compatibility() {
    echo -e "\n🔗 Validating cross-compatibility..."

    # Port conflict detection
    all_ports=()

    # Extract ports from devcontainer
    if [ -f ".devcontainer/devcontainer.json" ]; then
        devcontainer_ports=$(jq -r '.forwardPorts[]? // empty' .devcontainer/devcontainer.json 2>/dev/null || true)
        for port in $devcontainer_ports; do
            all_ports+=("$port")
        done
    fi

    # Extract ports from docker-compose
    if [ -f "docker-compose.yml" ]; then
        compose_ports=$(grep -E "^\s*-\s*[\"']?[0-9]+:[0-9]+" docker-compose.yml 2>/dev/null | sed 's/.*"\?\([0-9]\+\):.*/\1/' || true)
        for port in $compose_ports; do
            all_ports+=("$port")
        done
    fi

    # Check for port duplicates
    if [ ${#all_ports[@]} -gt 1 ]; then
        sorted_ports=($(printf '%s\n' "${all_ports[@]}" | sort))
        duplicates=($(printf '%s\n' "${sorted_ports[@]}" | uniq -d))

        if [ ${#duplicates[@]} -gt 0 ]; then
            echo -e "${RED}❌${NC} Port conflicts detected: ${duplicates[*]}"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${GREEN}✅${NC} No port conflicts detected"
        fi
    fi
}

# Validate devcontainer command timing and sequencing
validate_devcontainer_timing() {
    echo -e "\n⏰ Validating devcontainer command timing..."

    if [ -f ".devcontainer/devcontainer.json" ]; then
        # Check for potential timing issues
        post_create=$(jq -r '.postCreateCommand // empty' .devcontainer/devcontainer.json 2>/dev/null)
        post_start=$(jq -r '.postStartCommand // empty' .devcontainer/devcontainer.json 2>/dev/null)

        # Warn about commands that depend on features
        if echo "$post_create" | grep -qE '\b(npm|node|pip3|python3)\b'; then
            echo -e "${YELLOW}⚠️${NC} Post-create uses language commands that depend on features"
            echo -e "${BLUE}💡${NC} Consider using onCreateCommand instead, or add PATH/availability checks"

            # Check if using features
            has_node_feature=$(jq -r '.features | has("ghcr.io/devcontainers/features/node:1")' .devcontainer/devcontainer.json 2>/dev/null)
            has_python_feature=$(jq -r '.features | has("ghcr.io/devcontainers/features/python:1")' .devcontainer/devcontainer.json 2>/dev/null)

            if [ "$has_node_feature" = "true" ] && echo "$post_create" | grep -q npm; then
                echo -e "${RED}❌${NC} High risk: npm used in postCreateCommand with Node.js feature"
                echo -e "${YELLOW}💡${NC} Solution: Use 'source ~/.bashrc && npm install' or move to onCreateCommand"
                ERRORS=$((ERRORS + 1))
            fi

            if [ "$has_python_feature" = "true" ] && echo "$post_create" | grep -q pip3; then
                echo -e "${RED}❌${NC} High risk: pip3 used in postCreateCommand with Python feature"
                echo -e "${YELLOW}💡${NC} Solution: Use full path or move to onCreateCommand"
                ERRORS=$((ERRORS + 1))
            fi
        fi

        # Check for better alternatives
        if [ -n "$post_create" ] && [ -z "$post_start" ]; then
            echo -e "${GREEN}✅${NC} Using postCreateCommand (runs once during creation)"
        elif [ -z "$post_create" ] && [ -n "$post_start" ]; then
            echo -e "${GREEN}✅${NC} Using postStartCommand (runs every time)"
        elif [ -n "$post_create" ] && [ -n "$post_start" ]; then
            echo -e "${BLUE}ℹ️${NC} Using both postCreateCommand and postStartCommand"
        fi
    fi
}

# CRITICAL: Test post-create commands to catch 'command not found' errors
validate_post_create_commands() {
    echo -e "\n🔧 Validating post-create commands..."

    # Check if post-create command exists and is executable
    if [ -f ".devcontainer/devcontainer.json" ]; then
        post_create_cmd=$(jq -r '.postCreateCommand // empty' .devcontainer/devcontainer.json 2>/dev/null)
        if [ -n "$post_create_cmd" ]; then
            echo "Found post-create command: $post_create_cmd"

            # If it's a shell script, check if it exists and is executable
            if [[ "$post_create_cmd" =~ \.sh$ ]] && [ -f "$post_create_cmd" ]; then
                if [ -x "$post_create_cmd" ]; then
                    echo -e "${GREEN}✅${NC} Post-create script is executable: $post_create_cmd"
                else
                    echo -e "${RED}❌${NC} Post-create script not executable: $post_create_cmd"
                    ERRORS=$((ERRORS + 1))
                fi

                # Syntax check
                if bash -n "$post_create_cmd" 2>/dev/null; then
                    echo -e "${GREEN}✅${NC} Shell script syntax valid"
                else
                    echo -e "${RED}❌${NC} Shell script syntax errors found"
                    ERRORS=$((ERRORS + 1))
                fi
            fi

            # Test command availability that post-create might use
            echo "Checking command availability for post-create script..."

            # Check for common commands used in post-create
            commands_to_check=("npm" "node" "python3" "pip3" "git" "curl" "wget")
            for cmd in "${commands_to_check[@]}"; do
                if grep -q "$cmd" "$post_create_cmd" 2>/dev/null; then
                    if command -v "$cmd" >/dev/null 2>&1; then
                        echo -e "${GREEN}✅${NC} Required command available: $cmd"
                    else
                        echo -e "${RED}❌${NC} Required command NOT found: $cmd (will cause post-create failure)"
                        ERRORS=$((ERRORS + 1))
                    fi
                fi
            done
        fi
    fi
}

# Test environment variables and PATH
validate_environment() {
    echo -e "\n🌍 Validating environment setup..."

    # Check NODE_PATH and npm availability
    if command -v node >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} Node.js available: $(node --version)"

        if command -v npm >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} npm available: $(npm --version)"
        else
            echo -e "${RED}❌${NC} npm not found (Node.js installed but npm missing)"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "${YELLOW}⚠️${NC} Node.js not found (may be installed by features later)"
    fi

    # Check Python and pip availability
    if command -v python3 >/dev/null 2>&1; then
        echo -e "${GREEN}✅${NC} Python available: $(python3 --version)"

        if command -v pip3 >/dev/null 2>&1; then
            echo -e "${GREEN}✅${NC} pip3 available: $(pip3 --version)"
        else
            echo -e "${RED}❌${NC} pip3 not found (Python installed but pip missing)"
            ERRORS=$((ERRORS + 1))
        fi
    else
        echo -e "${YELLOW}⚠️${NC} Python not found (may be installed by features later)"
    fi

    # Check for devcontainer features PATH issues
    if [ -f ".devcontainer/devcontainer.json" ]; then
        has_node_feature=$(jq -r '.features | has("ghcr.io/devcontainers/features/node:1")' .devcontainer/devcontainer.json 2>/dev/null)
        if [ "$has_node_feature" = "true" ] && ! command -v npm >/dev/null 2>&1; then
            echo -e "${RED}❌${NC} Node.js feature configured but npm not available (PATH/timing issue)"
            echo -e "${YELLOW}💡${NC} This will cause post-create 'npm: command not found' errors"
            ERRORS=$((ERRORS + 1))
        fi

        has_python_feature=$(jq -r '.features | has("ghcr.io/devcontainers/features/python:1")' .devcontainer/devcontainer.json 2>/dev/null)
        if [ "$has_python_feature" = "true" ] && ! command -v pip3 >/dev/null 2>&1; then
            echo -e "${RED}❌${NC} Python feature configured but pip3 not available (PATH/timing issue)"
            ERRORS=$((ERRORS + 1))
        fi
    fi
}

# Run all validations in order
echo -e "${BLUE}Phase 1: Syntax Validation${NC}"
validate_json
validate_yaml
validate_docker

echo -e "${BLUE}Phase 2: Environment & Command Validation${NC}"
validate_post_create_commands
validate_environment
validate_post_create_dry_run

echo -e "${BLUE}Phase 3: LTS/Stable Version Validation${NC}"
validate_lts_versions

echo -e "${BLUE}Phase 4: Timing & Sequence Validation${NC}"
validate_devcontainer_timing

echo -e "${BLUE}Phase 5: Permission Validation${NC}"
validate_permissions

echo -e "${BLUE}Phase 6: Compatibility Validation${NC}"
validate_compatibility

# Final result
if [ $ERRORS -eq 0 ]; then
    echo -e "\n${GREEN}🎉 All validations passed! Safe to proceed with testing.${NC}"
    echo -e "${GREEN}✅ Syntax validation complete${NC}"
    echo -e "${GREEN}✅ Environment and command availability verified${NC}"
    echo -e "${GREEN}✅ Post-create commands tested${NC}"
    echo -e "${GREEN}✅ LTS/stable versions verified${NC}"
    echo -e "${GREEN}✅ Command timing and sequencing validated${NC}"
    echo -e "${GREEN}✅ Permissions secured${NC}"
    echo -e "${GREEN}✅ Cross-compatibility verified${NC}"
    exit 0
else
    echo -e "\n${RED}💥 $ERRORS validation errors found. Fix before testing!${NC}"
    echo -e "${RED}❌ Review the errors above and fix them one by one${NC}"
    echo -e "${YELLOW}💡 Run individual validation functions to focus on specific issues${NC}"
    echo -e "${YELLOW}🔒 Ensure all versions are LTS/stable before proceeding${NC}"
    exit 1
fi
```

## Emergency Contacts & Resources

### When All Else Fails

1. **Reset to minimal configuration**
2. **Use proven base images**: `mcr.microsoft.com/devcontainers/base:ubuntu`
3. **Remove all customizations** and add back incrementally
4. **Check Codespaces logs** in GitHub for detailed error messages

### Reference Implementations

- [Official Dev Container Templates](https://github.com/devcontainers/templates)
- [VS Code Remote Development](https://code.visualstudio.com/docs/remote/containers)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

### Version Pinning Strategy

Always pin to specific **LTS/stable** versions:

- **Node.js**: `22.9.0-alpine3.20` (LTS until October 2027)
- **Python**: `3.11.9-slim-bookworm` (LTS until October 2027)
- **Ubuntu**: `22.04` (LTS until April 2027)
- **Alpine**: `3.20` (LTS until April 2026)
- **npm packages**: Use `package-lock.json` with pinned LTS versions
- **pip packages**: Use `requirements.txt` with pinned stable versions

This document should be the single source of truth for all container configurations. When followed precisely, it guarantees successful builds and enables single-patch fixes for any issues that arise.

## Maintenance & Continuous Improvement

### Monthly Maintenance Checklist

- [ ] **Update LTS Version Table**: Check for new LTS releases and EOL dates
- [ ] **Test Base Images**: Verify recommended base images still build successfully
- [ ] **Update Validation Scripts**: Add new patterns based on encountered issues
- [ ] **Review Common Errors**: Add new error patterns discovered in the field

### Quarterly Review Process

- [ ] **Security Audit**: Review all base images for security vulnerabilities
- [ ] **Performance Optimization**: Analyze build times and image sizes for improvements
- [ ] **Feature Deprecation Check**: Verify devcontainer features haven't been deprecated
- [ ] **Documentation Updates**: Incorporate lessons learned and best practices discovered

### Continuous Learning Integration

```bash
# Add to post-create.sh to collect usage metrics
echo "📊 Collecting anonymous usage metrics..."
echo "$(date): Codespace created successfully" >> .devcontainer/usage.log
echo "Node version: $(node --version 2>/dev/null || echo 'N/A')" >> .devcontainer/usage.log
echo "Python version: $(python3 --version 2>/dev/null || echo 'N/A')" >> .devcontainer/usage.log
```

### Emergency Contact & Escalation

When these instructions fail to resolve issues:

1. **Level 1**: Check GitHub Codespaces Status Page
2. **Level 2**: Review recent devcontainer feature updates
3. **Level 3**: Consult Microsoft devcontainer documentation
4. **Level 4**: Create minimal reproduction case
5. **Level 5**: Escalate to platform team with detailed logs

### Success Metrics & KPIs

Track these metrics to measure configuration quality:

- **Build Success Rate**: Target > 98%
- **Build Time**: Target < 5 minutes for standard configs
- **Time to First Code**: Target < 2 minutes after creation
- **Extension Load Time**: Target < 1 minute
- **Zero Safe Mode Incidents**: Target 100%

Remember: **Stability over features, LTS over latest, validation over assumptions.**

---

## 🔄 Documentation Coverage Status

This comprehensive guide now covers all major Docker/DevContainer build failure patterns:

### ✅ Comprehensive Coverage Added (Latest Update)

- **User/Group Management**: UID/GID conflicts, existing user detection, permission issues
- **Container Exit Codes**: 125 (docker daemon errors), 126 (permission), 127 (command not found)
- **Build Context Issues**: Large contexts, .dockerignore problems, path resolution
- **Health Check Failures**: Timeout configurations, probe failures, startup sequences
- **Environment Variables**: Missing vars, substitution issues, encoding problems
- **File System Issues**: Mount failures, permission conflicts, path mappings
- **Resource Limits**: Memory/CPU constraints, disk space, concurrent builds
- **Image Optimization**: Layer caching, size optimization, multi-stage builds
- **Shell & Command Issues**: Path problems, script failures, signal handling
- **Network & Proxy**: SSL certificates, corporate firewalls, DNS resolution
- **Dependency Management**: Cache conflicts, version locks, platform compatibility
- **Process Management**: Zombie processes, graceful shutdowns, signal handling

### 🎯 Gap Analysis Results

**Before**: Limited error patterns, recurring issues not prevented
**After**: Comprehensive coverage of 12+ major error categories with specific solutions

### 🚀 Prevention Strategy

This documentation update ensures that common build failures are:

1. **Documented** with specific error patterns and solutions
2. **Preventable** through validation scripts and checklists
3. **Recoverable** with clear emergency procedures
4. **Trackable** through success metrics and KPIs

**Result**: Systematic approach to prevent recurring Docker/DevContainer issues through comprehensive documentation and proactive validation.
