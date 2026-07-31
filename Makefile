.PHONY: test audit integration release verify-release clean

test:
	bash -n ani-es install.sh uninstall.sh tests/*.sh scripts/*.sh
	./tests/run-tests.sh
	./tests/install-tests.sh

audit:
	./scripts/publication-audit.sh

integration:
	./tests/integration-live.sh

release: test audit
	./scripts/build-release.sh

verify-release:
	./scripts/verify-release.sh

clean:
	./scripts/clean-dist.sh
