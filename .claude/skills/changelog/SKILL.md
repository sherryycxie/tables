---
name: changelog
description: Summarize bug fixes and feature upgrades from the current Claude session
argument-hint: [format: posts|bullets]
---

# Session Changelog

Summarize the bug fixes and feature upgrades introduced during this Claude Code session.

## Arguments

- `$ARGUMENTS[0]` - Output format: `posts` (X/Twitter style) or `bullets` (bullet points). Default: `bullets`

## Instructions

Review the entire conversation history from this session and identify:

1. **Bug fixes**: Issues that were identified and resolved
2. **Feature upgrades**: New functionality or improvements added

Then format the summary based on the requested style.

### For `bullets` format (default):

- Create concise, **user-facing** bullet points (not technical/developer jargon)
- Focus on what the user experiences, not implementation details
- No file names, function names, or code references
- Maximum **5 bullet points** - prioritize the most impactful changes
- Start each with an action verb (Fixed, Added, Improved, etc.)
- Keep each bullet to 1 line, written in plain language
- Use a single flat list (no grouping by category)

Example output:
```
## What's New

- Fixed an issue where archived tables would sometimes reappear
- You can now swipe left on any table to quickly archive it
- Shared tables can now be archived without affecting other members
- Removed the arrow icons from the table list for a cleaner look
- Added "Leave" option to remove yourself from shared tables
```

### For `posts` format:

- Create engaging, shareable X/Twitter posts (under 280 characters each)
- Use developer-friendly language
- Include relevant hashtags like #iOS #SwiftUI #bugfix when appropriate
- Make them celebratory but professional

Example output:
```
## Session Changelog (X Posts)

1. Squashed a nasty race condition in our auth flow. Login failures? Gone. #iOS #SwiftUI

2. Just shipped dark mode support across the entire app. Your eyes will thank you at 2am #DarkMode #iOS

3. Optimized our table sync - 40% faster with smart batch updates. Performance matters! #SwiftUI
```

## Important

- Only include changes that were **actually made** during this session
- Do not include planned, hypothetical, or discussed-but-not-implemented changes
- If no meaningful changes were made, say so clearly
- Be accurate about what was fixed vs what was added as a new feature
- Generate a reasonable number of items based on actual work done - no need to pad or hit a specific count
