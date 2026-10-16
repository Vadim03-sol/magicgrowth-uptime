# MagicGrowth uptime

Every 5 minutes GitHub Actions checks the URLs in `urls.txt` and messages the
MagicGrowth Monitor Telegram bot when something goes down or comes back.
Add a line `name|url` to monitor more. Secrets: `TELEGRAM_TOKEN`, `TELEGRAM_CHAT_ID`.

Note: GitHub pauses scheduled workflows in a repository with no commits for
60 days — any commit (or re-enabling the workflow) resumes it.
