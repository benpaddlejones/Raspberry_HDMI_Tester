# Copilot Instructions Overview

This directory contains three complementary instruction files that guide GitHub Copilot when working on the Raspberry Pi HDMI Tester project.

## File Structure

```
.github/
├── copilot-instructions.md              # 16KB - Project-specific architecture & patterns
├── copilot-general-instructions.md      # 12KB - General coding principles & workflow
└── copilot-codespaces-instructions.md   # 76KB - Dev container & Codespaces configuration
```

## How They Work Together

### 1. **copilot-instructions.md** (THIS PROJECT)
**Scope**: Raspberry Pi HDMI Tester specific guidance
**When to reference**: Always when working on this project

Contains:
- ✅ Project architecture and technical stack
- ✅ Directory structure and naming conventions
- ✅ pi-gen build system rules and stage structure
- ✅ Raspberry Pi specific configurations (config.txt, cmdline.txt)
- ✅ Shell script standards for this project
- ✅ Testing requirements and hardware checklist
- ✅ Security considerations (privileged operations, SD card safety)
- ✅ Common tasks and troubleshooting patterns
- ✅ Project roadmap and current status

**Use when**:
- Creating or modifying build scripts
- Setting up pi-gen stages
- Configuring boot settings
- Adding systemd services
- Creating test assets
- Understanding project-specific requirements

---

### 2. **copilot-general-instructions.md** (CODING PRINCIPLES)
**Scope**: Universal coding best practices
**When to reference**: Every coding task across all projects

Contains:
- ✅ Autonomous workflow principles
- ✅ Code quality standards
- ✅ Error handling patterns
- ✅ Security best practices
- ✅ Commit message format (Conventional Commits)
- ✅ Separation of concerns and modularity
- ✅ Documentation standards

**Use when**:
- Writing any code (scripts, services, configs)
- Making architectural decisions
- Handling errors and edge cases
- Writing commit messages
- Ensuring code quality and maintainability

---

### 3. **copilot-codespaces-instructions.md** (DEVCONTAINER SETUP)
**Scope**: Development environment configuration
**When to reference**: When modifying dev container or debugging environment issues

Contains:
- ✅ devcontainer.json best practices
- ✅ Dockerfile optimization techniques
- ✅ LTS version strategy (CRITICAL for stability)
- ✅ Common build failure patterns and solutions
- ✅ Multi-stage build templates
- ✅ VS Code configuration standards
- ✅ Docker Compose patterns
- ✅ Validation checklists and diagnostic commands
- ✅ Troubleshooting guide for 10+ error categories

**Use when**:
- Modifying `.devcontainer/` files
- Debugging container build failures
- Adding new dependencies or tools
- Configuring VS Code settings
- Troubleshooting "command not found" errors
- Optimizing image size or build time

---

## Decision Matrix: Which File to Consult?

| Task | Primary Reference | Secondary Reference |
|------|------------------|-------------------|
| Creating build scripts | copilot-instructions.md | copilot-general-instructions.md |
| Modifying Dockerfile | copilot-codespaces-instructions.md | copilot-instructions.md |
| Adding systemd service | copilot-instructions.md | copilot-general-instructions.md |
| Fixing container errors | copilot-codespaces-instructions.md | - |
| Writing test scripts | copilot-instructions.md | copilot-general-instructions.md |
| Boot configuration | copilot-instructions.md | - |
| Code quality review | copilot-general-instructions.md | - |
| VS Code settings | copilot-codespaces-instructions.md | - |
| pi-gen stage setup | copilot-instructions.md | - |
| Commit messages | copilot-general-instructions.md | - |

---

## Priority Order for Copilot

When working on this project, Copilot should consult in this order:

1. **copilot-instructions.md** - Project-specific requirements ALWAYS come first
2. **copilot-general-instructions.md** - General coding principles for implementation
3. **copilot-codespaces-instructions.md** - Only when dealing with dev environment

### Example Scenarios

#### Scenario A: Creating `build-image.sh`
```
1. Read copilot-instructions.md → Learn pi-gen conventions, stage system, shell standards
2. Read copilot-general-instructions.md → Apply error handling, code quality standards
3. Skip copilot-codespaces-instructions.md → Not relevant for this task
```

#### Scenario B: Fixing "npm: command not found" in post-create.sh
```
1. Read copilot-codespaces-instructions.md → Find Error Category 1 solution
2. Read copilot-instructions.md → Check project-specific timing requirements
3. Read copilot-general-instructions.md → Apply debugging workflow
```

#### Scenario C: Adding Audio Test Service
```
1. Read copilot-instructions.md → Learn systemd service patterns, audio requirements
2. Read copilot-general-instructions.md → Apply coding standards and modularity
3. Skip copilot-codespaces-instructions.md → Not relevant for runtime service
```

---

## Critical Rules (All Files)

### From copilot-instructions.md
- ⚠️ **Never use `latest` tags** - Always specify versions
- ⚠️ **Privileged mode required** - For loop device mounting
- ⚠️ **ARM target** - Code runs on Raspberry Pi, not x86
- ⚠️ **Size matters** - Keep image minimal (< 4GB target)

### From copilot-general-instructions.md
- ⚠️ **Autonomous operation** - Complete tasks without stopping
- ⚠️ **Minimal scope** - Only change what's necessary
- ⚠️ **Preserve existing behavior** - Don't break working code
- ⚠️ **Conventional Commits** - Use proper commit format

### From copilot-codespaces-instructions.md
- ⚠️ **LTS versions only** - Use Long-Term Support releases
- ⚠️ **Pin versions** - Specify exact versions (e.g., `22.9.0` not `22`)
- ⚠️ **Non-root user** - Use existing users, don't create conflicting UIDs
- ⚠️ **Validate before deploy** - Run all validation commands

---

## Quick Reference

### For Developers
- **Starting a new task?** → Read copilot-instructions.md first
- **Writing code?** → Follow copilot-general-instructions.md principles
- **Container broken?** → Check copilot-codespaces-instructions.md troubleshooting

### For Copilot
- **Project context** → copilot-instructions.md
- **Coding standards** → copilot-general-instructions.md
- **Environment issues** → copilot-codespaces-instructions.md

---

## Maintenance

### When to Update These Files

**copilot-instructions.md** - Update when:
- Project architecture changes
- New build stages added
- Testing procedures evolve
- New tools or dependencies introduced

**copilot-general-instructions.md** - Update when:
- Coding standards change
- New workflow patterns emerge
- Team conventions evolve

**copilot-codespaces-instructions.md** - Update when:
- New error patterns discovered
- LTS versions change
- Docker/container best practices evolve
- New validation techniques identified

---

## Summary

These three files form a **layered instruction system**:

```
┌─────────────────────────────────────────┐
│   copilot-instructions.md               │  ← Project DNA
│   (What to build, how this project      │
│    works, Raspberry Pi specifics)       │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│   copilot-general-instructions.md       │  ← Coding DNA
│   (How to write code, quality           │
│    standards, workflows)                │
└─────────────────────────────────────────┘
                  ↓
┌─────────────────────────────────────────┐
│   copilot-codespaces-instructions.md    │  ← Environment DNA
│   (Where code runs, container setup,    │
│    troubleshooting)                     │
└─────────────────────────────────────────┘
```

Together, they provide comprehensive guidance for building a stable, maintainable, and well-documented Raspberry Pi HDMI testing tool.

---

**Last Updated**: October 16, 2025
**Maintained By**: Project team
