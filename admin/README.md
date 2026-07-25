# Project Earth Admin Panel

Phase 0 only defines the admin workspace and secure bootstrap rules. Do not commit real admin passwords, session secrets, API keys, database dumps, or production logs.

## Local Bootstrap Rule

Use `PROJECT_EARTH_ADMIN_USERNAME` and `PROJECT_EARTH_ADMIN_BOOTSTRAP_PASSWORD` from a local `.env` file during development. The future admin implementation must hash the bootstrap password immediately and must never expose it to the game client.
