# README Contract Source Section

Use one of these blocks near the top of the frontend README files.

## Editor-page
```md
## Contract Source
- Contract Repo: https://github.com/jho951/service-contract
- Contract Lock: `contract.lock.yml`
- Repo Role: frontend consumer
- Branch: master

## Contract Scope
- Uses `Ui-components-module` for shared UI components
- Current v1 document and block flows
- Document tree operations: list, detail, edit, save, move, restore, trash
- Block content editing and ordering
- Future Node migration is tracked separately in contract docs
```

## Explain-page
```md
## Contract Source
- Contract Repo: https://github.com/jho951/service-contract
- Contract Lock: `contract.lock.yml`
- Repo Role: frontend consumer
- Branch: main

## Contract Scope
- Uses `Ui-components-module` for shared UI components
- Login, refresh, logout, and session handling
- User context and social-link flows exposed through the gateway
```

## Notes
- Keep this section near the top of the README, right after the project summary.
- Keep the pinned contract ref and consumed contract list in `contract.lock.yml`.
- If the page uses only a subset of the contract, list the specific docs and UI flows in `contract.lock.yml`.
