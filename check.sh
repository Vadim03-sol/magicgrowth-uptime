#!/usr/bin/env bash
# MagicGrowth uptime: checks every URL in urls.txt twice (30 s apart) and
# messages Telegram only when a check changes state (down / back up), with a
# reminder every hour while something stays down. State lives in state/.
set -u
mkdir -p state
now=$(date +%s)
send() {
  curl -s -o /dev/null --max-time 15 "https://api.telegram.org/bot${TELEGRAM_TOKEN}/sendMessage" \
    --data-urlencode "chat_id=${TELEGRAM_CHAT_ID}" --data-urlencode "text=$1"
}
probe() {
  local body code
  body=$(curl -s --max-time 25 -w '\n%{http_code}' "$1") || return 1
  code=${body##*$'\n'}; body=${body%$'\n'*}
  [ "$code" = "200" ] || { echo "HTTP $code $(echo "$body" | grep -o '"[a-z]*":{"ok":false[^}]*}' | tr '\n' ' ')"; return 1; }
  echo "$body" | grep -q '"ok":false' && { echo "$(echo "$body" | grep -o '"[a-z]*":{"ok":false[^}]*}' | tr '\n' ' ')"; return 1; }
  return 0
}
grep -v '^#' urls.txt | grep '|' | while IFS='|' read -r name url; do
  if detail=$(probe "$url"); then status=up; else sleep 30; if detail=$(probe "$url"); then status=up; else status=down; fi; fi
  prev=$(cat "state/$name" 2>/dev/null || echo "up 0")
  prev_status=${prev%% *}; prev_alert=${prev##* }
  if [ "$status" = down ] && { [ "$prev_status" = up ] || [ $((now - prev_alert)) -ge 3600 ]; }; then
    send "🔴 ${name} nefunguje: ${detail:-bez odpovědi} — ${url}"
    echo "down $now" > "state/$name"
  elif [ "$status" = up ] && [ "$prev_status" = down ]; then
    send "🟢 ${name} znovu funguje"
    echo "up $now" > "state/$name"
  elif [ "$status" = down ]; then
    echo "down $prev_alert" > "state/$name"
  else
    echo "up $now" > "state/$name"
  fi
  echo "$name: $status ${detail:-}"
done
