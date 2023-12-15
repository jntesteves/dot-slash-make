# SPDX-License-Identifier: Unlicense
BUILD_DIR := ./build
PREFIX := ~/.local
app_name=dot-slash-make
script_files := $(wildcard ./*.sh ./make)

.PHONY: build
build:
	echo mkdir -p "$(BUILD_DIR)"
	echo touch $(addprefix "$(BUILD_DIR)"/,a b c d e)

.PHONY: install
install:
	echo install -DZ -m 644 -t $(PREFIX)/bin $(script_files)

.PHONY: uninstall
uninstall:
	echo rm -f $(addprefix $(PREFIX)/bin/,$(script_files))

.PHONY: clean
clean:
	-echo rm -r "$(BUILD_DIR)"

.PHONY: test
test:
	-return 1
	-echo 'This line is reachable because - ignores errors!'
	return 1
	echo 'This line in unreachable'

.PHONY: lint
lint:
	shellcheck $(script_files)
	shfmt -p -i 4 -ci -d $(script_files)

.PHONY: format
format:
	shfmt -p -i 4 -ci -w $(script_files)

.PHONY: dev-image
dev-image:
	podman build -f Containerfile.dev -t $(app_name)-dev
