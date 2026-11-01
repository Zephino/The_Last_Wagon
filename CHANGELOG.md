# Changelog

## Version 00.01.02
Date: 11/01/2026
Time: 12:06 AM

### Changes
- Added `.cursor/rules/think-before-acting.mdc`: ask questions until 95% sure, give a short summary and a 2-line plan, then wait for the owner's go-ahead before changing anything.

### Reason
The owner asked for this rule. `dependency.mdc` already referred to it by this filename, but the file was missing.

## Version 00.01.01
Date: 10/31/2026
Time: 11:38 PM

### Changes
- Added a "Pushing" owner rule to `CLAUDE.md`: finished work is always pushed to the `main` branch.

### Reason
The owner asked for all work to always be uploaded to `main`.

## Version 00.01.00
Date: 10/31/2026
Time: 11:37 PM

### Changes
- Added the general project rules from Wave Defence to `.cursor/rules/`: bug investigation, changelog, performance, dependencies, documentation, focused functions, data protection, and versioning.
- Added `CLAUDE.md` so Claude Code follows the same rules as Cursor.
- Added `VERSION` (starting at `00.01.00`) and this changelog, as the version and changelog rules require.

### Reason
Reuse Wave Defence's general working rules in The Last Wagon. Wave Defence-specific rules (retro music generation, Godot build and publishing steps) were left out.
