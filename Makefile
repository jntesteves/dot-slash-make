BUILD_DIR := ./build
PREFIX := ~/.local
FLAGS := -a -b -c
app_name := dot-slash-make
dist_bin := ./dist/$(app_name).sh
script_files := $(wildcard ./src/*.sh ./*.sh ./make $(dist_bin))
ifndef NO_SELINUX
selinux_flag := -Z
endif
programs := a b c d e
artifacts := $(addprefix "$(BUILD_DIR)"/,$(programs))

.PHONY: dist
dist:
	shellcheck $(script_files)
	shfmt -d $(script_files)
	./nice_modules/nice_things/nice_build.sh
	shfmt -w $(dist_bin)
	-diff ./dot-slash-make.sh $(dist_bin)

.PHONY: build
build:
	./nice_modules/nice_things/nice_build.sh
	-diff ./dot-slash-make.sh $(dist_bin)
	mkdir -p "$(BUILD_DIR)"
	touch $(artifacts)

.PHONY: install
install:
	install -D $(selinux_flag) -m 755 -t $(PREFIX)/bin $(artifacts)

.PHONY: uninstall
uninstall:
	rm -f $(addprefix $(PREFIX)/bin/,$(programs))

.PHONY: clean
clean:
	-rm -r "$(BUILD_DIR)"

.PHONY: test
test:
	-return 1
	@echo 'This line is reachable because - ignores errors! FLAGS=$(FLAGS)'
	return 1
	@echo 'This line in unreachable'

.PHONY: lint
lint:
	shellcheck $(script_files)
	shfmt -d $(script_files)

.PHONY: format
format:
	shfmt -w $(script_files)

.PHONY: dev-image
dev-image:
	podman build -f Containerfile.dev -t $(app_name)-dev
