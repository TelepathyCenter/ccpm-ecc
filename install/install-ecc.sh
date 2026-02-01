#!/bin/bash
# CCPM-ECC Installer
# Installs CCPM (trimmed for Everything Claude Code compatibility) into the current project.
# Prerequisites: Everything Claude Code plugin must be installed globally.
#
# Usage: Run from your project root:
#   bash <(curl -s https://raw.githubusercontent.com/TelepathyCenter/ccpm-ecc/main/install/install-ecc.sh)
#
# Or clone and run:
#   git clone https://github.com/TelepathyCenter/ccpm-ecc.git /tmp/ccpm-ecc
#   bash /tmp/ccpm-ecc/install/install-ecc.sh
#   rm -rf /tmp/ccpm-ecc

set -e

REPO_URL="https://github.com/TelepathyCenter/ccpm-ecc.git"
TMPDIR=$(mktemp -d)

echo ""
echo "CCPM-ECC Installer"
echo "==================="
echo "Installing CCPM (Everything Claude Code compatible) into: $(pwd)"
echo ""

# Check prerequisites
if ! command -v gh &> /dev/null; then
  echo "WARNING: GitHub CLI (gh) not found. Install it before running /pm:init"
fi

if ! command -v git &> /dev/null; then
  echo "ERROR: git is required"
  exit 1
fi

if [ ! -d ".git" ]; then
  echo "ERROR: Not a git repository. Run 'git init' first."
  exit 1
fi

# Clone to temp
echo "Fetching CCPM-ECC..."
git clone --depth 1 --quiet "$REPO_URL" "$TMPDIR"

# Create directory structure
echo "Creating directories..."
mkdir -p .claude/agents
mkdir -p .claude/commands/pm
mkdir -p .claude/commands/context
mkdir -p .claude/commands/testing
mkdir -p .claude/rules
mkdir -p .claude/scripts/pm
mkdir -p .claude/hooks
mkdir -p .claude/context
mkdir -p .claude/epics
mkdir -p .claude/prds

# Copy CCPM files
echo "Copying files..."
cp "$TMPDIR"/ccpm/agents/*.md .claude/agents/
cp "$TMPDIR"/ccpm/commands/pm/*.md .claude/commands/pm/
cp "$TMPDIR"/ccpm/commands/context/*.md .claude/commands/context/
cp "$TMPDIR"/ccpm/commands/testing/*.md .claude/commands/testing/
cp "$TMPDIR"/ccpm/commands/code-rabbit.md .claude/commands/
cp "$TMPDIR"/ccpm/commands/prompt.md .claude/commands/
cp "$TMPDIR"/ccpm/commands/re-init.md .claude/commands/
cp "$TMPDIR"/ccpm/rules/*.md .claude/rules/
cp "$TMPDIR"/ccpm/scripts/pm/*.sh .claude/scripts/pm/
cp "$TMPDIR"/ccpm/scripts/test-and-log.sh .claude/scripts/
cp "$TMPDIR"/ccpm/scripts/check-path-standards.sh .claude/scripts/
cp "$TMPDIR"/ccpm/scripts/fix-path-standards.sh .claude/scripts/
cp "$TMPDIR"/ccpm/hooks/bash-worktree-fix.sh .claude/hooks/
cp "$TMPDIR"/ccpm/context/README.md .claude/context/
cp "$TMPDIR"/ccpm/ccpm.config .claude/
touch .claude/epics/.gitkeep
touch .claude/prds/.gitkeep

# Make scripts executable
chmod +x .claude/scripts/pm/*.sh .claude/scripts/*.sh .claude/hooks/*.sh 2>/dev/null || true

# Update .gitignore
echo "Updating .gitignore..."
if [ -f ".gitignore" ]; then
  # Remove broad .claude/ ignore if present
  if grep -q "^\.claude/$" .gitignore 2>/dev/null; then
    sed -i.bak '/^\.claude\/$/d' .gitignore && rm -f .gitignore.bak
    echo "Removed broad .claude/ from .gitignore (replaced with specific ignores)"
  fi
fi

# Add specific ignores if not already present
for pattern in ".claude/epics/" ".claude/settings.local.json"; do
  if ! grep -qF "$pattern" .gitignore 2>/dev/null; then
    echo "$pattern" >> .gitignore
  fi
done

# Create settings.local.json if it doesn't exist
if [ ! -f ".claude/settings.local.json" ]; then
  echo "Creating default settings.local.json..."
  cat > .claude/settings.local.json << 'SETTINGS'
{
  "permissions": {
    "allow": [
      "Bash(bash .claude/scripts/*)",
      "Bash(.claude/scripts/*)",
      "Bash(git:*)",
      "Bash(gh:*)",
      "Bash(cat:*)",
      "Bash(date:*)",
      "Bash(find:*)",
      "Bash(grep:*)",
      "Bash(kill:*)",
      "Bash(ls:*)",
      "Bash(mv:*)",
      "Bash(rm:*)",
      "Bash(sed:*)",
      "Bash(touch:*)",
      "Bash(tree:*)",
      "WebSearch",
      "WebFetch(domain:github.com)"
    ]
  }
}
SETTINGS
else
  echo "settings.local.json already exists - skipping (add CCPM permissions manually if needed)"
fi

# Create CLAUDE.md if it doesn't exist
if [ ! -f "CLAUDE.md" ]; then
  REPO_NAME=$(basename "$(git remote get-url origin 2>/dev/null | sed 's/\.git$//')" 2>/dev/null || echo "project")
  echo "Creating CLAUDE.md..."
  cat > CLAUDE.md << CLAUDEMD
# CLAUDE.md

> Think carefully and implement the most concise solution that changes as little code as possible.

## Prerequisites

This repo requires the [Everything Claude Code](https://github.com/affaan-m/everything-claude-code) plugin installed globally before use. CCPM's rules depend on ECC for coding standards, TDD methodology, and conventional commits. Install ECC first, then clone this repo and run \`/pm:init\`.

## Project: ${REPO_NAME}

## PM Agents (project-level)

| Agent | Purpose | When to Use |
|-------|---------|-------------|
| code-analyzer | Bug hunting in code diffs | Analyzing changes for issues |
| file-analyzer | Summarize large files/logs (80-90% token savings) | Before reading large output |
| parallel-worker | Coordinate parallel worktree execution | Multi-stream PM issues |
| test-runner | Run tests with structured logging | Test execution and reporting |

## PM Workflow

Use \`/pm:help\` for full command reference. Key commands:
- \`/pm:prd-new <name>\` - Start new feature with PRD
- \`/pm:epic-decompose <name>\` - Break PRD into tasks
- \`/pm:epic-sync <name>\` - Push to GitHub Issues
- \`/pm:issue-start <number>\` - Begin work on an issue
- \`/pm:status\` - Project dashboard
CLAUDEMD
else
  echo "CLAUDE.md already exists - skipping (add PM agent roster manually if needed)"
fi

# Cleanup
rm -rf "$TMPDIR"

echo ""
echo "Done! CCPM-ECC installed successfully."
echo ""
echo "Next steps:"
echo "  1. Run /pm:init to set up GitHub labels"
echo "  2. Run /pm:help to see all commands"
echo "  3. Run /pm:prd-new <name> to create your first PRD"
echo ""
