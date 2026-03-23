# Ralph Setup Guide

Ralph is an autonomous AI agent loop that runs AI coding tools (Amp or Claude Code) repeatedly until all user stories in a PRD are complete. Each iteration spawns a fresh AI instance with clean context. Memory persists across iterations via git history, `progress.txt`, and `prd.json`.

Based on [Geoffrey Huntley's Ralph pattern](https://ghuntley.com/ralph/). Source repo: [snarktank/ralph](https://github.com/snarktank/ralph).

---

## Prerequisites

- **AI coding tool** (one of):
  - [Amp CLI](https://ampcode.com) — installed and authenticated
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code) — `npm install -g @anthropic-ai/claude-code`
- **jq** — `brew install jq` (used by `ralph.sh` to parse `prd.json`)
- **Git** — your project must be a git repository

---

## Step 1: Create the Ralph Directory

```bash
mkdir -p scripts/ralph
```

---

## Step 2: Copy Core Files

From the [snarktank/ralph](https://github.com/snarktank/ralph) repo, copy these files into `scripts/ralph/`:

### `ralph.sh` — The Loop Script

```bash
cp /path/to/ralph/ralph.sh scripts/ralph/ralph.sh
chmod +x scripts/ralph/ralph.sh
```

This is the bash loop that:
- Archives previous runs when the branch name changes
- Spawns a fresh AI instance per iteration
- Checks for the `<promise>COMPLETE</promise>` stop signal
- Supports `--tool amp` (default) or `--tool claude`

### Agent Prompt Template

Copy the template for your AI tool of choice:

```bash
# For Claude Code:
cp /path/to/ralph/CLAUDE.md scripts/ralph/CLAUDE.md

# For Amp:
cp /path/to/ralph/prompt.md scripts/ralph/prompt.md
```

---

## Step 3: Customize the Agent Prompt

Edit `scripts/ralph/CLAUDE.md` (or `prompt.md` for Amp) to match your project. The key sections to customize:

### Quality Check Commands

Replace the generic quality checks with your project's specific commands:

```markdown
## Quality Requirements

- ALL commits must pass: `bundle exec rspec` and `bundle exec rubocop`
- Do NOT commit broken code
- Run `bin/rails db:migrate` after creating migrations
- Run `bin/rails db:test:prepare` before running specs
```

### Project-Specific Conventions

Add any patterns, gotchas, or conventions the agent should follow. For example:

```markdown
- Use Stimulus controllers in `app/javascript/controllers/`
- Use `before_action :authenticate_user!` for auth in controllers
- Follow existing factory patterns in `spec/factories/`
```

### Stop Condition

The prompt must include the stop signal so Ralph knows when to exit:

```markdown
## Stop Condition

After completing a user story, check if ALL stories have `passes: true`.

If ALL stories are complete and passing, reply with:
<promise>COMPLETE</promise>
```

---

## Step 4: Create the `prd.json`

This is the task list Ralph works through. Create `scripts/ralph/prd.json` with this structure:

```json
{
  "project": "YourProjectName",
  "branchName": "ralph/feature-name-kebab-case",
  "description": "Brief description of the feature set being built",
  "userStories": [
    {
      "id": "US-001",
      "title": "Short descriptive title",
      "description": "As a [user], I want [feature] so that [benefit]",
      "acceptanceCriteria": [
        "Specific verifiable criterion 1",
        "Specific verifiable criterion 2",
        "All specs pass: `bundle exec rspec`",
        "`bundle exec rubocop` passes"
      ],
      "priority": 1,
      "passes": false,
      "notes": "Optional hints, gotchas, or context for the agent"
    }
  ]
}
```

### Key Rules for User Stories

1. **Small stories** — Each story must be completable in one AI context window. If it's too big, the LLM runs out of context and produces poor code.

   ✅ Right-sized:
   - Add a database column and migration
   - Add a UI component to an existing page
   - Update a service with new logic

   ❌ Too big (split these):
   - "Build the entire dashboard"
   - "Add authentication"
   - "Refactor the API"

2. **Dependency order** — Lower priority number = done first. Schema → service → controller → view.

3. **Verifiable acceptance criteria** — Every criterion must be checkable. "Works correctly" is bad. "Returns 404 when record not found" is good.

4. **Always include quality checks** — Add your test/lint commands as criteria:
   ```
   "All existing specs pass: `bundle exec rspec`",
   "`bundle exec rubocop` passes"
   ```

5. **Use the `notes` field** — Give the agent hints about gotchas:
   ```
   "notes": "The timing change from 4000→5000 may break specs that hardcode 4000ms. Search spec/ for '4000' and update."
   ```

6. **All stories start as `passes: false`** — Ralph picks the highest-priority `false` story each iteration.

---

## Step 5: Initialize Progress Tracking

Create an empty progress file (or let `ralph.sh` create it automatically):

```bash
echo "# Ralph Progress Log" > scripts/ralph/progress.txt
echo "Started: $(date)" >> scripts/ralph/progress.txt
echo "---" >> scripts/ralph/progress.txt
```

Ralph appends to this file after each story. It also maintains a `## Codebase Patterns` section at the top with reusable learnings that persist across iterations.

---

## Step 6: Run Ralph

```bash
# Using Claude Code (with max 20 iterations):
./scripts/ralph/ralph.sh --tool claude 20

# Using Amp (default tool, 10 iterations):
./scripts/ralph/ralph.sh 10
```

Ralph will:
1. Read `prd.json` and check out the specified branch (creating it from `main` if needed)
2. Pick the highest-priority story where `passes: false`
3. Implement that single story
4. Run quality checks (tests, linting)
5. Commit if checks pass
6. Set `passes: true` in `prd.json` for the completed story
7. Append learnings to `progress.txt`
8. Repeat until all stories pass or max iterations reached

### Monitoring Progress

While Ralph runs, you can check status in another terminal:

```bash
# See which stories are done
cat scripts/ralph/prd.json | jq '.userStories[] | {id, title, passes}'

# See learnings from iterations
cat scripts/ralph/progress.txt

# Check git history
git log --oneline -10
```

---

## Directory Structure

After setup, your ralph directory should look like:

```
scripts/ralph/
├── ralph.sh          # The bash loop (executable)
├── CLAUDE.md         # Agent prompt for Claude Code
├── prd.json          # Current task list (user stories)
├── progress.txt      # Append-only learnings log
└── archive/          # Auto-created; stores previous runs
    └── 2026-03-21-feature-name/
        ├── prd.json
        └── progress.txt
```

---

## Archiving

Ralph automatically archives previous runs when it detects a new `branchName` in `prd.json`. The old `prd.json` and `progress.txt` are copied to `archive/YYYY-MM-DD-feature-name/` and `progress.txt` is reset.

You can also manually archive before starting a new feature:

```bash
mkdir -p scripts/ralph/archive/$(date +%Y-%m-%d)-old-feature
cp scripts/ralph/prd.json scripts/ralph/archive/$(date +%Y-%m-%d)-old-feature/
cp scripts/ralph/progress.txt scripts/ralph/archive/$(date +%Y-%m-%d)-old-feature/
```

---

## Tips & Lessons Learned

### Writing Good PRDs for Ralph

- **Be explicit in acceptance criteria.** The agent follows them literally. "Update the view" is vague. "Add a `data-round-target='timerText'` element that displays the countdown" is actionable.
- **Include file paths in notes.** If you know which files need changes, tell the agent: `"notes": "The timer logic is in app/javascript/controllers/round_controller.js"`
- **Warn about cascading changes.** If changing a constant will break other specs, say so: `"notes": "Changing 4000→5000 will break specs in question_stat_sync_service_spec.rb"`
- **One concern per story.** Don't mix migration + service + view + specs in one story. Split them.

### Iteration Count

- Simple features (5-10 stories): `--tool claude 15` is usually enough
- Large features (20-30 stories): `--tool claude 35` gives headroom
- Each story typically takes 1 iteration, but failures/retries add more

### When Ralph Gets Stuck

- Check `progress.txt` for error patterns
- Look at the last few git commits to see what was attempted
- You can manually fix an issue, commit, and re-run Ralph — it will pick up where it left off
- If a story is too large, split it into smaller stories in `prd.json`

### The CLAUDE.md / AGENTS.md Flywheel

Ralph updates `CLAUDE.md` files with discovered patterns after each iteration. This means later iterations benefit from earlier learnings. The longer Ralph runs on your project, the smarter it gets about your codebase.

---

## Optional: Install Skills Globally

If you use Amp or Claude Code across multiple projects, install the PRD and Ralph converter skills globally:

```bash
# For Amp:
cp -r /path/to/ralph/skills/prd ~/.config/amp/skills/
cp -r /path/to/ralph/skills/ralph ~/.config/amp/skills/

# For Claude Code:
cp -r /path/to/ralph/skills/prd ~/.claude/skills/
cp -r /path/to/ralph/skills/ralph ~/.claude/skills/
```

This gives you two skills usable in any project:
- **prd skill** — Generate a PRD from a feature description (ask it: "create a prd for [feature]")
- **ralph skill** — Convert a markdown PRD to `prd.json` format (ask it: "convert this prd to ralph format")

---

## Quick-Start Checklist

- [ ] `jq` installed (`brew install jq`)
- [ ] AI tool installed (Claude Code or Amp)
- [ ] `scripts/ralph/` directory created
- [ ] `ralph.sh` copied and made executable (`chmod +x`)
- [ ] Agent prompt copied and customized (`CLAUDE.md` or `prompt.md`)
- [ ] Quality check commands updated in agent prompt
- [ ] `prd.json` created with small, ordered, verifiable user stories
- [ ] Run: `./scripts/ralph/ralph.sh --tool claude 20`
