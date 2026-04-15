---
title: TypeScript Rules
description: TypeScript coding standards and best practices
globs: "**/*.{ts,tsx}"
---

## Types

- Prefer `interface` for object shapes, `type` for unions/intersections.
- Avoid `any`. Use `unknown` when type is truly unknown, then narrow.
- Use `as const` for literal types instead of type assertions.
- Export types that are part of public API. Keep internal types unexported.

## Patterns

- Use discriminated unions for state machines and variants.
- Prefer `Map`/`Set` over plain objects for dynamic keys.
- Use `satisfies` operator to validate types without widening.
- Avoid enums — use `as const` objects or union types instead.

## Async

- Always handle promise rejections.
- Prefer `async/await` over `.then()` chains.
- Use `Promise.all` for independent concurrent operations.
- Avoid floating promises — always await or void-annotate intentional fire-and-forget.

## Imports

- Use named exports. Default exports only for framework conventions (React components, Next.js pages).
- Group imports: external deps, internal modules, relative imports.
- Avoid barrel files (`index.ts` re-exports) in large projects — they hurt tree-shaking.
