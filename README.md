# RobynBase

## Setup

Run `bin/setup` to set up a new development environment. It assumes that the following have already been installed on your system:

1. Ruby (v3.4 or above)
2. Node (v24 or above)
3. yarn (v1.22 or above)

## Development Notes

### Auditing via PaperTrail

This application uses PaperTrail to track changes to its models. PaperTrail registration is handled via the `audited` method in the `Auditable` concern - **not** via direct calls to `has_paper_trail`. Keep this in mind when adding new models that need to be audited. **Note:** this is enforced by unit tests, which will fail if you use `has_paper_trail` directly.

The auditing behaviour is covered by two test files:

- `test/models/audit_hierarchy_test.rb` — pins the audit hierarchy that `AuditHierarchy` derives from ActiveRecord associations, and reconciles the `audited` registry against the models PaperTrail actually tracks (this is the test that fails if you call `has_paper_trail` directly).
- `test/models/audit_event_test.rb` — covers how the denormalized `audit_events` summary and the `AuditActivity` presenter classify and headline a transaction's changes.

## Pre-commit hook

A versioned pre-commit hook (`.githooks/pre-commit`) runs the full test suite — `bin/rails test` followed by `yarn test` — and blocks the commit if anything fails. It is activated automatically by `bin/setup`; to enable it manually in an existing clone:

```sh
git config core.hooksPath .githooks
```

In a genuine emergency you can bypass it with `git commit --no-verify`.
