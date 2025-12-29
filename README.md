# jirabot5000

A CLI tool that fetches all tickets under a Jira epic, formats them as readable markdown, and optionally analyzes them with Claude AI, all from a single command line tool.

```bash
./jirabot5000 ABCD-123
# Downloads tickets → Formats as markdown → Analyzes with Claude
```

## Why Use This?

- **Get instant insights** - Understand epic progress, blockers, and risks in seconds
- **No manual copying** - Automatically fetches all child tickets from any epic
- **AI-powered analysis** - Claude identifies blockers, unassigned work, and stale tickets
- **Markdown output** - Easy to read, share, and version control

## Requirements

Before you start, make sure you have:

- **Python 3.11+** - Check with `python3 --version`
- **[uv](https://docs.astral.sh/uv/)** - Python package manager (`curl -LsSf https://astral.sh/uv/install.sh | sh`)
- **[Claude CLI](https://claude.com/code)** - Optional, but needed for automatic analysis

## Setup (First Time)

**Quick check:** Run `make setup` to check if you have everything installed.

### 1. Get Your Jira API Token

Visit https://id.atlassian.com/manage-profile/security/api-tokens and create a new token.

### 2. Create Your Config File

Copy the example config:

```bash
cp config.json.example config.json
```

Edit `config.json` with your details:

```json
{
  "jira_instance": "your-company.atlassian.net",
  "email": "your-email@example.com",
  "output_directory": "."
}
```

### 3. Set Your API Token

**Recommended approach** (keeps credentials out of files):

```bash
export JIRA_API_TOKEN="your-jira-api-token"
```

To make this permanent, add it to your `~/.bashrc` or `~/.zshrc`:

```bash
echo 'export JIRA_API_TOKEN="your-jira-api-token"' >> ~/.zshrc
```

**Alternative approach** (add to config.json):

```json
{
  "jira_instance": "your-company.atlassian.net",
  "email": "your-email@example.com",
  "api_token": "your-jira-api-token",
  "output_directory": "."
}
```

Note: `config.json` is gitignored, but environment variables are more secure.

### 4. Verify Setup

Check that everything is configured correctly:

```bash
make setup
```

This will verify:
- ✓ Python 3.11+ is installed
- ✓ uv is installed
- ✓ Claude CLI is installed (optional)
- ✓ config.json exists and is configured
- ✓ JIRA_API_TOKEN is set

Then test with a real epic:

```bash
./jirabot5000 ABCD-123
```

You should see:
- ✓ Fetching epic...
- ✓ Found X tickets
- ✓ Formatting...
- Prompt: "Run Claude analysis? (Y/n)"

## Quick Start

### Analyze an Epic

```bash
./jirabot5000 ABCD-970
```

**What happens:**
1. Downloads epic + all child tickets from Jira
2. Formats them as readable markdown → `ABCD-970/summary.md`
3. Prompts: "Run Claude analysis? (Y/n)"
4. Analyzes with Claude → `ABCD-970/analysis.md`

**Output:**
```
ABCD-970/
├── ABCD-970.json       # Epic metadata
├── TICKET-1.json        # Individual tickets (JSON)
├── TICKET-2.json
├── summary.md           # Formatted markdown (human-readable)
└── analysis.md          # Claude analysis results
```

### Review Before Analyzing

```bash
./jirabot5000 ABCD-123
# When prompted, type "n"

# Review the summary first
cat ABCD-123/summary.md

# Analyze later if you want
cat ABCD-123/summary.md | claude --print > ABCD-123/analysis.md
```

## Usage Examples

### Batch Process Multiple Epics

```bash
for epic in EPIC-1 EPIC-2 EPIC-3; do
  ./jirabot5000 $epic
done
```

### Download Only (No Analysis)

```bash
# Download and format, but skip Claude analysis
JIRABOT_DOWNLOAD_ONLY=1 ./jirabot5000 ABCD-123
```

### Custom Analysis Prompts

```bash
# Generate summary without analysis
./jirabot5000 ABCD-123
# (choose "n" when prompted)

# Create your own analysis prompt
cat > custom-prompt.md <<EOF
Focus on security concerns and technical debt.
List all tickets that mention "security" or "vulnerability".
EOF

# Analyze with custom prompt
cat custom-prompt.md ABCD-123/summary.md | claude --print > ABCD-123/security-analysis.md
```

### Re-analyze Existing Data

```bash
# Already downloaded an epic? Re-analyze without re-downloading
cat ABCD-123/summary.md | claude --print > ABCD-123/analysis-v2.md
```

### Using the Makefile

```bash
# Download + format + analyze
make run EPIC=ABCD-123

# Download only
make download EPIC=ABCD-123

# Format existing download
make format EPIC=ABCD-123
```

## Troubleshooting

### "claude: command not found"

**Option 1: Install Claude CLI** (recommended)
- Visit https://claude.com/code
- Follow installation instructions
- Re-run `./jirabot5000 ABCD-123`

**Option 2: Analyze manually**
```bash
# Copy summary to clipboard
cat ABCD-123/summary.md | pbcopy
# Then paste into claude.ai web interface
```

### "config.json not found"

Make sure you created the config file:

```bash
cp config.json.example config.json
# Then edit config.json with your details
```

### "Authentication failed" or 401 errors

Check your credentials:

1. **API token is valid** - Test it at https://id.atlassian.com/manage-profile/security/api-tokens
2. **Email is correct** - Must match your Jira account email
3. **Jira instance domain** - Should be `company.atlassian.net` (no `https://`)
4. **Token has permissions** - Token must have read access to Jira projects

### "Epic not found" or 404 errors

Common issues:

- **Typo in epic key** - Epic keys are case-sensitive (e.g., `ABCD-970` not `abcd-970`)
- **No access to project** - Your Jira account must have access to the project
- **Epic vs Issue** - Make sure you're using an epic key, not a regular issue key

### Analysis takes too long

For very large epics (50+ tickets), Claude may take several minutes. The default timeout is 5 minutes.

If it consistently times out:

```bash
# Analyze manually with streaming (no timeout)
cat ABCD-123/summary.md | claude

# Or split analysis into chunks
head -n 500 ABCD-123/summary.md | claude --print > ABCD-123/analysis-part1.md
tail -n +501 ABCD-123/summary.md | claude --print > ABCD-123/analysis-part2.md
```

## Configuration Reference

### Environment Variables

- `JIRA_API_TOKEN` - Your Jira API token (recommended over config file)
- `JIRABOT_DOWNLOAD_ONLY=1` - Skip formatting and analysis

### Config File (`config.json`)

| Field | Required | Description | Example |
|-------|----------|-------------|---------|
| `jira_instance` | ✓ | Your Jira domain | `company.atlassian.net` |
| `email` | ✓ | Your Jira account email | `user@example.com` |
| `api_token` | * | Jira API token | `ATATT3xFfGF0...` |
| `output_directory` | | Where to save results | `.` (current dir) |

\* Required if `JIRA_API_TOKEN` environment variable is not set

## How It Works

1. **Download** - Fetches epic + child tickets via Jira REST API v3 (`/rest/api/3/search/jql`)
2. **Format** - Converts Jira's JSON format to clean, readable markdown
3. **Analyze** - Sends summary to Claude for analysis of progress, blockers, and risks

**Technical Details:**
- Uses modern Jira Cloud REST API v3 with JQL `parent = {epic_key}`
- Automatic pagination for epics with 50+ tickets
- Extracts plain text from Confluence document format
- Zero config dependencies via `uv` (PEP 723 inline metadata)

## What Gets Analyzed

When you run Claude analysis, it identifies:

- **Progress metrics** - Completion percentage, tickets by status
- **Blockers & risks** - Unassigned tickets, stale work (no updates in 30+ days)
- **Key decisions** - Important updates from recent comments
- **Recommendations** - Actionable next steps

Results are saved to `{EPIC}/analysis.md` with a quick summary printed to console.

## Tips

- Review `summary.md` before analyzing - it's human-readable and might be all you need
- Analysis results are saved to `analysis.md` so you can reference them later
- Re-run analysis anytime without re-downloading (saves time on large epics)
- Use download-only mode (`JIRABOT_DOWNLOAD_ONLY=1`) for batch processing
- Add epic directories to `.gitignore` if you don't want to commit downloaded data

## License

This software uses the MIT license. See `LICENSE` for more details.
