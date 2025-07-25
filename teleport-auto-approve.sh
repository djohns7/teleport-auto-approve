#!/bin/bash

LOCKFILE="/home/teleport-bot/lockfile"
IDENTITY="/home/teleport-bot/identity"
PROXY="danjdemo.teleport.sh"
TSH_BIN="/usr/local/bin/tsh"
TCTL_BIN="/usr/local/bin/tctl"

PENDING=false
REQUEST_IDS=()
APPROVED_SEEN=false

# ---------- LOCK MODE ----------
if [ -f "$LOCKFILE" ]; then
  while read -r line; do
    STATUS=$(echo "$line" | awk '{print $NF}')
    if [ "$STATUS" = "APPROVED" ]; then
      APPROVED_SEEN=true
      break
    fi
  done < <("$TSH_BIN" --identity="$IDENTITY" --proxy="$PROXY" requests ls | tail -n +3)

  if $APPROVED_SEEN; then
    if ! "$TCTL_BIN" --auth-server "${PROXY}:443" -i "$IDENTITY" get locks | grep -q "role: contractor-admin"; then
      "$TCTL_BIN" --auth-server "${PROXY}:443" -i "$IDENTITY" lock \
        --role=contractor-admin \
        --message="All contractor access is disabled while in lock." \
        --ttl=1h
      echo "[$(date -u)] LOCKED contractor-admin due to active approved request and lock mode"
    fi
  fi

  exit 0
fi

# ---------- NORMAL MODE ----------
while read -r line; do
  STATUS=$(echo "$line" | awk '{print $NF}')
  if [ "$STATUS" = "PENDING" ]; then
    ID=$(echo "$line" | awk '{print $1}')
    REQUEST_IDS+=("$ID")
    PENDING=true
  fi
done < <("$TSH_BIN" --identity="$IDENTITY" --proxy="$PROXY" requests ls | tail -n +3)

if $PENDING; then
  for ID in "${REQUEST_IDS[@]}"; do
    "$TSH_BIN" --identity="$IDENTITY" --proxy="$PROXY" request review --approve "$ID"
    echo "[$(date -u)] APPROVED request ID $ID"
  done
fi