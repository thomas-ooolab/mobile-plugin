---
title: React Native Rules
description: React Native development standards
globs: "**/*.{tsx,jsx}"
---

## Components

- Use functional components with hooks. No class components.
- Keep components small. Extract sub-components when a component exceeds ~150 lines.
- Use `StyleSheet.create()` for styles — avoid inline style objects.
- Memoize expensive components with `React.memo` and expensive computations with `useMemo`.

## Navigation

- Type all navigation params. Use typed navigation hooks.
- Keep navigation logic in screen components, not deep children.
- Handle deep links explicitly.

## Performance

- Use `FlatList` for long lists, never `ScrollView` with `.map()`.
- Avoid unnecessary re-renders — profile with React DevTools.
- Use `useCallback` for callbacks passed to child components.
- Minimize bridge crossings — batch native calls where possible.

## Platform

- Use `Platform.select()` for platform-specific values.
- Keep platform-specific code in `.ios.ts` / `.android.ts` files when differences are large.
- Test on both platforms before merging.
