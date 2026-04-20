# Monitoring README Contract Source Section

Use this block near the top of the `monitoring-service` README.

```md
## Contract Source
- Contract Repo: https://github.com/jho951/service-contract
- Contract Lock: `contract.lock.yml`
- Repo Role: observability runtime
- Branch: main

## Contract Scope
- Prometheus scrape target and label conventions
- Grafana dashboard and alert rule ownership
- Loki/Promtail log collection boundaries
- Operator-only access and secret handling
- Retention, backup, readiness, and config validation
- audit events: `shared/audit.md`
```

## Notes
- Keep this section near the top of the README, right after the project summary.
- Keep the pinned contract ref and consumed contract list in `contract.lock.yml`.
- Monitoring is an infra/observability repo, not a backend business API service.
