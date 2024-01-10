BUILD_DIR := ./build
PREFIX := ~/.local
FLAGS := -a -b -c
app_name=dot-slash-make
script_files := $(wildcard ./*.sh ./make)
ifndef NO_SELINUX
selinux_flag := -Z
endif
programs := a b c d e
artifacts := $(addprefix "$(BUILD_DIR)"/,$(programs))

.PHONY: build
build:
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
	-echo 'This line is reachable because - ignores errors!'
	return 1
	echo 'This line in unreachable' $(FLAGS)

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
