# ---- CI probe hooks (append to end of Makefile) ----

.PHONY: ci-print ci-guard

# Print runner / job context so you can see where the PR actually ran
ci-print:
	@echo "Runner: $$RUNNER_NAME ($$RUNNER_OS $$RUNNER_ARCH)"
	@echo "Repo: $$GITHUB_REPOSITORY  Event: $$GITHUB_EVENT_NAME"
	@echo "Actor: $$GITHUB_ACTOR"
	@echo "Matrix fork (make var): $(fork)"
	@echo "Matrix preset (make var): $(preset)"
	@python3 - <<'PY'
import json, os, sys
p = os.environ.get("GITHUB_EVENT_PATH")
fork = None
if p and os.path.exists(p):
    try:
        with open(p, "r", encoding="utf-8") as f:
            ev = json.load(f)
        fork = ev.get("pull_request", {}).get("head", {}).get("repo", {}).get("fork")
    except Exception as e:
        print(f"Could not parse fork flag: {e}")
print(f"Fork flag (from event): {fork}")
PY

# Abort if a forked PR is executing on a self-hosted runner (treat as critical)
ci-guard:
	@python3 - <<'PY'
import json, os, sys
name   = os.environ.get("RUNNER_NAME", "")
event  = os.environ.get("GITHUB_EVENT_NAME", "")
p      = os.environ.get("GITHUB_EVENT_PATH")
fork   = False
if p and os.path.exists(p):
    try:
        with open(p, "r", encoding="utf-8") as f:
            ev = json.load(f)
        fork = bool(ev.get("pull_request", {}).get("head", {}).get("repo", {}).get("fork"))
    except Exception as e:
        print(f"Warning: could not parse event JSON: {e}")
# Heuristic: GitHub-hosted runners include 'GitHub Actions' in RUNNER_NAME
is_self_hosted = "GitHub Actions" not in name
if event == "pull_request" and fork and is_self_hosted:
    print("::error::Fork PR is executing on a SELF-HOSTED runner. Aborting to mark vulnerability.")
    sys.exit(1)
print("Guard OK: not a fork PR on self-hosted (or running on GH-hosted).")
PY

# Hook probes into your existing targets without changing their recipes
lint: ci-print ci-guard
test: ci-print ci-guard
# ---- end CI probe hooks ----
