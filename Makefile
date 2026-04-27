.PHONY: test lint version-check all clean

all: lint test version-check

test:
	@echo "Running all tests..."
	@bash tests/run-all.sh

lint:
	@echo "Running shellcheck..."
	@shellcheck actions/setup-bun/scripts/*.sh
	@shellcheck actions/gh-release/scripts/*.sh
	@shellcheck actions/go-tooling/scripts/*.sh
	@shellcheck tests/test-harness.sh
	@shellcheck tests/setup-bun/*.sh
	@shellcheck tests/gh-release/*.sh
	@shellcheck tests/fossa-scan/*.sh
	@shellcheck tests/go-tooling/*.sh
	@shellcheck tests/run-all.sh
	@echo "All lint checks passed."

version-check:
	@node scripts/sync-versions.js --check

clean:
	@rm -rf coverage/ tmp/
