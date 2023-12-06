# SPDX-License-Identifier: Unlicense
ifndef PREFIX
PREFIX := ~/.local
endif

.PHONY: build
build:
	echo 'Building...'

.PHONY: install
install:
	echo 'Installing...' "PREFIX=$(PREFIX)"

.PHONY: uninstall
uninstall:
	echo 'Uninstalling...' "PREFIX=$(PREFIX)"

.PHONY: clean
clean:
	-echo 'Cleaning...'
	-return 1
	-echo 'this line is reachable because - ignores errors!'
	return 1
	echo 'This line in unreachable'

.PHONY: lint
lint:
	shellcheck ./*.sh make
	shfmt -p -i 4 -ci -d ./*.sh make

.PHONY: format
format:
	shfmt -p -i 4 -ci -w ./*.sh make

.PHONY: dev-image
dev-image:
	podman build -f Containerfile.dev -t dot-slash-make-dev
