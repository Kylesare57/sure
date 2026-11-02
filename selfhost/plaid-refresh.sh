#!/usr/bin/env bash
# Ask Plaid to check OnPoint for new transactions right now, then sync into Sure.
# Uses Sure's built-in PlaidItem#sync_later_with_provider_refresh
# (Plaid /transactions/refresh + sync, with Sure's own 5-minute cooldown).
#
# Install on the Pi:
#   cp plaid-refresh.sh ~/docker-apps/sure/ && chmod +x ~/docker-apps/sure/plaid-refresh.sh
#   crontab -e   and add (every 2 hours, at :17 past):
#   17 */2 * * * $HOME/docker-apps/sure/plaid-refresh.sh >> $HOME/docker-apps/sure/plaid-refresh.log 2>&1

set -euo pipefail
cd "$(dirname "$0")"

echo "[$(date '+%F %T')] requesting Plaid refresh"
docker compose exec -T web bin/rails runner '
  items = PlaidItem.syncable.to_a
  puts "  #{items.size} Plaid connection(s)"
  items.each do |item|
    item.sync_later_with_provider_refresh
    puts "  queued refresh + sync for #{item.name}"
  end
'
