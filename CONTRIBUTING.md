# Contributing to temida

## Setup

```
git clone https://github.com/nulljosh/temida.git
cd temida
```

## Test

The checklist id check needs `ChecklistIndex.swift` compiled with it:

```
swiftc -O ios/Sources/Models/ChecklistIndex.swift ios/Sources/Models/Limitation.swift tests/main.swift -o /tmp/clidx && /tmp/clidx
```

CI runs that from `.github/workflows/test.yml`. `node tools/test-leverage.mjs` checks the leverage math. CI does not run it.

## Making a change

- Keep the diff scoped to what you're fixing or adding — no drive-by refactors.
- Match the existing code style in the file you're touching.
- Open a PR with a short description of the why, not just the what.

## Reporting a bug

Open a GitHub issue with steps to reproduce — the smaller the repro, the faster it gets fixed.
