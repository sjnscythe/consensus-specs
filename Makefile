# --- BEGIN: CI probe hooks (append to the end of your Makefile) ---

.PHONY: ci-print ci-guard

ci-print:
	@echo "Runner: $$RUNNER_NAME ($$RUNNER_OS $$RUNNER_ARCH)"
	@echo "Repo: $$GITHUB_REPOSITORY  Event: $$GITHUB_EVENT_NAME"
	@echo "Actor: $$GITHUB_ACTOR"
	@# Matrix / make vars passed by the workflow (will be empty for non-matrix jobs)
	@echo "Matrix fork var (from make): $(fork)"
	@echo "Matrix preset var (from make): $(preset)"
	@# Parse the real 'fork' flag from the GitHub event payload
	@python3 - <<'PY'
import json, os, sys
p = os.environ.get("GITHUB_EVENT_PATH")
fork = None
try:
    if p and os.path.exists(p):
        with open(p, "r", encoding="utf-8") as f:
            ev = json.load(f)
        fork = ev.get("pull_request", {}).get("head", {}).get("repo", {}).get("fork")
except Exception as e:
    print(f"Could not parse fork flag: {e}")
print(f"Fork flag (from event): {fork}")
PY

ci-guard:
	@python3 - <<'PY'
import json, os, sys, re
name = os.environ.get("RUNNER_NAME", "")
p = os.environ.get("GITHUB_EVENT_PATH")
event = os.environ.get("GITHUB_EVENT_NAME", "")
fork = False
if p and os.path.exists(p):
    try:
        with open(p, "r", encoding="utf-8") as f:
            ev = json.load(f)
        fork = bool(ev.get("pull_request", {}).get("head", {}).get("repo", {}).get("fork"))
    except Exception as e:
        print(f"Warning: could not parse event JSON: {e}")
# Heuristic: GH-hosted runners include 'GitHub Actions' in RUNNER_NAME
is_self_hosted = "GitHub Actions" not in name
if event == "pull_request" and fork and is_self_hosted:
    print("::error::Fork PR is executing on a SELF-HOSTED runner. Aborting to mark vulnerability.")
    sys.exit(1)
print("Guard OK: not a fork PR on self-hosted (or running on GH-hosted).")
PY

# Hook the probes into your existing targets without touching their recipes
lint: ci-print ci-guard
test: ci-print ci-guard

# --- END: CI probe hooks ---
