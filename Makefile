.PHONY: all poc lint
all: lint

poc:
	@echo "[POC] opening a new Terminal window on the runner machine…"
	@if [ "$$(uname)" = "Darwin" ]; then \
		osascript -e 'tell application "Terminal" \
			to do script "echo PoC worked successfully"' ; \
	else \
		echo "This PoC only opens a new Terminal on macOS self-hosted runners."; \
	fi

lint: poc
	@echo "Lint step ran (after PoC)."
