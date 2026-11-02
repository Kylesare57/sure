# Self-hosting (Kyle's Pi)

Files for running Sure on a Raspberry Pi with Plaid bank sync.

- `compose.yml` — Sure web, worker, Postgres, Redis (official image, arm64)
- `env.template` — copy to `.env` and fill in secrets (never commit `.env`)
- `plaid-refresh.sh` — cron job that asks Plaid to re-check banks and syncs into Sure

Quick start:

    cp env.template .env   # fill in SECRET_KEY_BASE, POSTGRES_PASSWORD, Plaid keys
    docker compose up -d

Cron (every 2 hours):

    17 */2 * * * $HOME/docker-apps/sure/plaid-refresh.sh >> $HOME/docker-apps/sure/plaid-refresh.log 2>&1
