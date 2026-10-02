# 0008 — Client-side navigation with a stack per tab, encoded in the URL

- **Status:** accepted
- **Date:** 2026-10-02

## Context
Brief §9 asks for native-feeling navigation: five tabs, each keeping its own stack, screens that
slide in from the right, an edge swipe back, and instant switching between tabs. Next.js route
changes fetch a server payload per screen, so a push can't start moving until the network
answers, and they don't work offline.

## Decision
Inside the app shell (`sotto-web`), moving between screens is a `history.pushState`, not a
Next.js route change. Next.js keeps `usePathname()` in sync, and a reload of any URL renders
the same screen on the server.

- The URL encodes a tab's whole stack: `/docs/collection/c_1/doc/d_42` is
  [Docs, Collection, Document]. A deep link rebuilds the stack, so Back works straight away.
- A small store (`src/lib/nav/store.ts`) holds the location, each tab's last URL and the in-app
  history (to tell back from forward); React reads it with `useSyncExternalStore`.
- Every screen in a stack stays mounted; transitions run as Web Animations with spring easings
  on the compositor, and can be interrupted or driven by a finger.
- Hidden tabs live in React `<Activity>` and `content-visibility: hidden`, so switching back is a
  style change with scroll positions intact.

## Consequences
- A push starts on the next frame and navigation works offline (with the service worker).
- Screens fetch their own data (TanStack Query) instead of receiving it from the server route.
- Links inside the shell use `NavLink`; outside links and modified clicks behave like any link.
- Revisit if Next.js gains client-only route transitions with the same latency.
