---
title: Code Review
description: Structured code review checklist and process
---

When reviewing code, check these areas in order:

## 1. Correctness
- Does the code do what it claims to do?
- Are edge cases handled?
- Are there off-by-one errors, null checks, or race conditions?

## 2. Security
- Input validation present?
- No secrets or credentials in code?
- SQL injection, XSS, or other injection risks?
- Authentication/authorization properly checked?

## 3. Performance
- Any N+1 queries or unnecessary loops?
- Large data sets handled efficiently?
- Caching used where appropriate?
- No memory leaks (event listeners, subscriptions cleaned up)?

## 4. Maintainability
- Code is readable without excessive comments?
- Functions and variables named clearly?
- No unnecessary complexity or premature abstraction?
- Tests cover the important paths?

## 5. Architecture
- Changes consistent with existing patterns?
- Dependencies appropriate?
- API contracts clear and backward-compatible?

Output format: list findings as `[severity] file:line — description` where severity is one of: 🔴 critical, 🟡 warning, 🔵 suggestion.
