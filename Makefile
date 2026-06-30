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
	@shellcheck actions/build-pkg-rpm/scripts/*.sh
	@shellcheck actions/build-pkg-deb/scripts/*.sh
	@shellcheck actions/npm-publish/scripts/*.sh
	@shellcheck actions/release/scripts/*.sh
	@shellcheck actions/deploy-pages/scripts/*.sh
	@shellcheck actions/checkout/scripts/*.sh
	@shellcheck actions/setup-go/scripts/*.sh
	@shellcheck actions/setup-node/scripts/*.sh
	@shellcheck actions/setup-python/scripts/*.sh
	@shellcheck actions/upload-pages-artifact/scripts/*.sh
	@shellcheck actions/deploy-pages-api/scripts/*.sh
	@shellcheck actions/codeql-common/scripts/*.sh
	@shellcheck actions/codeql-init/scripts/*.sh
	@shellcheck actions/codeql-autobuild/scripts/*.sh
	@shellcheck actions/codeql-analyze/scripts/*.sh
	@shellcheck actions/audit-supply-chain/scripts/*.sh
	@shellcheck actions/upload-artifact/scripts/*.sh
	@shellcheck actions/download-artifact/scripts/*.sh
	@shellcheck actions/configure-pages/scripts/*.sh
	@shellcheck tests/test-harness.sh
	@shellcheck tests/setup-bun/*.sh
	@shellcheck tests/gh-release/*.sh
	@shellcheck tests/fossa-scan/*.sh
	@shellcheck tests/go-tooling/*.sh
	@shellcheck tests/build-pkg-rpm/*.sh
	@shellcheck tests/build-pkg-deb/*.sh
	@shellcheck tests/npm-publish/*.sh
	@shellcheck tests/release/*.sh
	@shellcheck tests/deploy-pages/*.sh
	@shellcheck tests/checkout/*.sh
	@shellcheck tests/setup-go/*.sh
	@shellcheck tests/setup-node/*.sh
	@shellcheck tests/setup-python/*.sh
	@shellcheck tests/upload-pages-artifact/*.sh
	@shellcheck tests/deploy-pages-api/*.sh
	@shellcheck tests/codeql/*.sh
	@shellcheck tests/audit-supply-chain/*.sh
	@shellcheck tests/upload-artifact/*.sh
	@shellcheck tests/download-artifact/*.sh
	@shellcheck tests/configure-pages/*.sh
	@shellcheck tests/run-all.sh
	@echo "All lint checks passed."

version-check:
	@node scripts/sync-versions.js --check

clean:
	@rm -rf coverage/ tmp/
