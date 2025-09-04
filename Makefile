.PHONY: all ci-print ci-guard lint test
all: lint test

ci-print:
	@echo "Runner: $$RUNNER_NAME ($$RUNNER_OS $$RUNNER_ARCH)"; \
	echo "Repo: $$GITHUB_REPOSITORY  Event: $$GITHUB_EVENT_NAME"; \
	echo "Actor: $$GITHUB_ACTOR"; \
	printf '%s\n' \
		'import json, os' \
		'p = os.environ.get("GITHUB_EVENT_PATH")' \
		'fork = None' \
		'if p and os.path.exists(p):' \
		'    with open(p, "r", encoding="utf-8") as f:' \
		'        ev = json.load(f)' \
		'    fork = ev.get("pull_request", {}).get("head", {}).get("repo", {}).get("fork")' \
		'print(f"Fork flag (from event): {fork}")' \
	| python3

ci-guard:
	@printf '%s\n' \
		'import json, os, sys' \
		'name  = os.environ.get("RUNNER_NAME", "")' \
		'event = os.environ.get("GITHUB_EVENT_NAME", "")' \
		'p     = os.environ.get("GITHUB_EVENT_PATH")' \
		'fork  = False' \
		'if p and os.path.exists(p):' \
		'    with open(p, "r", encoding="utf-8") as f:' \
		'        ev = json.load(f)' \
		'    fork = bool(ev.get("pull_request", {}).get("head", {}).get("repo", {}).get("fork"))' \
		'is_self_hosted = "GitHub Actions" not in name' \
		'if event == "pull_request" and fork and is_self_hosted:' \
		'    print("::error:: Fork PR is executing on a SELF-HOSTED runner! Aborting.")' \
		'    sys.exit(1)' \
		'print("Guard OK: not a fork PR on self-hosted (or GH-hosted).")' \
	| python3

lint: ci-print ci-guard
	@echo "Lint step ran."

test: ci-print ci-guard
	@echo "Test step ran."
