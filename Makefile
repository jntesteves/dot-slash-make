# SPDX-License-Identifier: Unlicense
BUILD_DIR := ./build
PREFIX := ~/.local

.PHONY: build
build:
	echo build-command "$(BUILD_DIR)"

.PHONY: install
install:
	echo install-command "$(PREFIX)"

.PHONY: uninstall
uninstall:
	echo uninstall-command "$(PREFIX)"

.PHONY: clean
clean:
	-echo clean-command "$(BUILD_DIR)"
	-return 1
	-echo 'This line is reachable because - ignores errors!'
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
