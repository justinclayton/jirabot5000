.PHONY: help setup run download format clean

# Default target
help:
	@echo "jirabot5000 - Jira Epic Ticket Fetcher & Analyzer"
	@echo ""
	@echo "Available targets:"
	@echo "  make setup                    - Check prerequisites and guide first-time setup"
	@echo "  make run EPIC=<epic-key>      - Download + format + prompt for analysis (recommended)"
	@echo "  make download EPIC=<epic-key> - Download tickets only (no format/analysis)"
	@echo "  make format EPIC=<epic-key>   - Format existing download to summary.md"
	@echo "  make clean                    - Remove downloaded epic directories"
	@echo ""
	@echo "Example usage:"
	@echo "  make setup                        # First-time setup (run this first!)"
	@echo "  make run EPIC=VCDLD-970           # Interactive workflow with analysis"
	@echo "  make download EPIC=VCDLD-970      # Just download raw JSON"
	@echo "  make format EPIC=VCDLD-970        # Format existing download"
	@echo ""
	@echo "Note: The scripts use uv's inline script dependencies."
	@echo "Dependencies are automatically managed when you run the scripts."
	@echo ""
	@echo "v2.0: Default 'run' target now includes auto-formatting and optional analysis."
	@echo "Use 'download' target for old behavior (download only)."

# Setup: Check prerequisites and guide first-time setup
setup:
	@echo "════════════════════════════════════════════════════════════════"
	@echo "jirabot5000 Setup - Checking Prerequisites"
	@echo "════════════════════════════════════════════════════════════════"
	@echo ""
	@# Check Python version
	@echo "→ Checking Python..."
	@if command -v python3 >/dev/null 2>&1; then \
		PYTHON_VERSION=$$(python3 --version | sed 's/Python //'); \
		PYTHON_MAJOR=$$(echo $$PYTHON_VERSION | cut -d. -f1); \
		PYTHON_MINOR=$$(echo $$PYTHON_VERSION | cut -d. -f2); \
		if [ $$PYTHON_MAJOR -ge 3 ] && [ $$PYTHON_MINOR -ge 11 ]; then \
			echo "  ✓ Python $$PYTHON_VERSION (meets requirement: 3.11+)"; \
		else \
			echo "  ✗ Python $$PYTHON_VERSION (requires 3.11+)"; \
			echo "    Install from: https://www.python.org/downloads/"; \
			exit 1; \
		fi; \
	else \
		echo "  ✗ Python 3 not found"; \
		echo "    Install from: https://www.python.org/downloads/"; \
		exit 1; \
	fi
	@echo ""
	@# Check uv
	@echo "→ Checking uv..."
	@if command -v uv >/dev/null 2>&1; then \
		UV_VERSION=$$(uv --version | sed 's/uv //'); \
		echo "  ✓ uv $$UV_VERSION"; \
	else \
		echo "  ✗ uv not found (required for dependency management)"; \
		echo "    Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"; \
		echo "    Or visit: https://docs.astral.sh/uv/"; \
		exit 1; \
	fi
	@echo ""
	@# Check Claude CLI
	@echo "→ Checking Claude CLI..."
	@if command -v claude >/dev/null 2>&1; then \
		echo "  ✓ claude CLI installed"; \
	else \
		echo "  ⚠ claude CLI not found (optional, but needed for automatic analysis)"; \
		echo "    Install from: https://claude.com/code"; \
		echo "    Or skip analysis and use: cat EPIC-123/summary.md | pbcopy"; \
	fi
	@echo ""
	@# Check config.json
	@echo "→ Checking config.json..."
	@if [ -f config.json ]; then \
		echo "  ✓ config.json exists"; \
		if grep -q '"jira_instance".*"your-company.atlassian.net"' config.json 2>/dev/null; then \
			echo "  ⚠ config.json still has placeholder values"; \
			echo "    Edit config.json with your Jira instance and email"; \
		fi; \
	else \
		echo "  ✗ config.json not found"; \
		if [ -f config.json.example ]; then \
			echo "    Run: cp config.json.example config.json"; \
			echo "    Then edit config.json with your details"; \
		else \
			echo "    Create config.json with:"; \
			echo '    {'; \
			echo '      "jira_instance": "your-company.atlassian.net",'; \
			echo '      "email": "your-email@example.com",'; \
			echo '      "output_directory": "."'; \
			echo '    }'; \
		fi; \
		exit 1; \
	fi
	@echo ""
	@# Check JIRA_API_TOKEN
	@echo "→ Checking JIRA_API_TOKEN..."
	@if [ -n "$$JIRA_API_TOKEN" ]; then \
		echo "  ✓ JIRA_API_TOKEN environment variable is set"; \
	else \
		if grep -q '"api_token"' config.json 2>/dev/null; then \
			echo "  ✓ api_token found in config.json"; \
		else \
			echo "  ⚠ JIRA_API_TOKEN not set (required for authentication)"; \
			echo "    Option 1 (recommended): export JIRA_API_TOKEN=\"your-token\""; \
			echo "    Option 2: Add \"api_token\": \"your-token\" to config.json"; \
			echo ""; \
			echo "    Get your token from:"; \
			echo "    https://id.atlassian.com/manage-profile/security/api-tokens"; \
		fi; \
	fi
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "Setup Summary"
	@echo "════════════════════════════════════════════════════════════════"
	@if command -v python3 >/dev/null 2>&1 && command -v uv >/dev/null 2>&1 && [ -f config.json ]; then \
		echo "✓ All required prerequisites are installed!"; \
		echo ""; \
		echo "Next steps:"; \
		echo "  1. Ensure config.json has your Jira details"; \
		echo "  2. Set JIRA_API_TOKEN environment variable (or add to config.json)"; \
		echo "  3. Run your first epic: make run EPIC=YOUR-EPIC-123"; \
	else \
		echo "⚠ Some prerequisites are missing. Please install them first."; \
	fi
	@echo ""

# Run the full workflow: download + format + prompt for analysis
run:
	@if [ -z "$(EPIC)" ]; then \
		echo "Error: EPIC parameter required"; \
		echo "Usage: make run EPIC=VCDLD-970"; \
		exit 1; \
	fi
	./jirabot5000 $(EPIC)

# Download only (no format/analysis) - legacy mode
download:
	@if [ -z "$(EPIC)" ]; then \
		echo "Error: EPIC parameter required"; \
		echo "Usage: make download EPIC=VCDLD-970"; \
		exit 1; \
	fi
	@echo "Note: Using download-only mode (no format/analysis)"
	@echo "For full workflow with analysis, use: make run EPIC=$(EPIC)"
	@echo ""
	JIRABOT_DOWNLOAD_ONLY=1 ./jirabot5000 $(EPIC)

# Format existing epic to summary.md
format:
	@if [ -z "$(EPIC)" ]; then \
		echo "Error: EPIC parameter required"; \
		echo "Usage: make format EPIC=VCDLD-970"; \
		exit 1; \
	fi
	@if [ ! -d "$(EPIC)" ]; then \
		echo "Error: Directory $(EPIC)/ not found"; \
		echo "Run: make run EPIC=$(EPIC)"; \
		exit 1; \
	fi
	./format-epic $(EPIC)/ > $(EPIC)/summary.md
	@echo "Formatted summary saved to $(EPIC)/summary.md"

# Clean up downloaded epic directories
clean:
	@echo "Cleaning up downloaded epic directories..."
	@echo ""
	@echo "Directories matching pattern: *-[0-9]*"
	@ls -d *-[0-9]* 2>/dev/null | grep -E '^[A-Z]+-[0-9]+$$' || echo "  (none found)"
	@echo ""
	@read -p "Remove these directories? [y/N] " confirm && \
	if [ "$$confirm" = "y" ] || [ "$$confirm" = "Y" ]; then \
		rm -rf $$(ls -d *-[0-9]* 2>/dev/null | grep -E '^[A-Z]+-[0-9]+$$') && echo "Directories removed"; \
	else \
		echo "Cancelled"; \
	fi
