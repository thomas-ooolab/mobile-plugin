---
title: Specs
description: Accept ticket ID + requirements, execute full 5-step development workflow
---

# Specs

Arguments: $ARGUMENTS

Accept a **ticket ID** and **requirements** from the user, then execute the full development workflow defined in `../rules/development-workflow.md`.

If `$ARGUMENTS` is non-empty, parse it as `<ticket-id> <requirements>` (e.g. `LOE-6144 add dark mode toggle`). Use the first token as the ticket ID and the remainder as the requirements. If `$ARGUMENTS` is empty, prompt the user for ticket ID and requirements.

**Strictly follow steps 1 → 5 in order.** Each step must be fully completed before moving to the next. Do not skip or reorder any step.
