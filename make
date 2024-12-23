#!/bin/sh
# shellcheck disable=SC2046,SC2086
. ./dot-slash-make.sh

param BUILD_DIR=./build
param PREFIX="${HOME}/.local"
param FLAGS='-a -b -c'
FLAGS=$(list_from "${FLAGS}")
app_name=dot-slash-make
dist_bin=./dist/${app_name}.sh
script_files=$(wildcard ./src/*.sh ./*.sh ./make ${dist_bin})
selinux_flag=-Z
# In sh we can detect if the SELinux flag is supported instead of requiring a CLI parameter
case $(install -Z 2>&1) in *'unrecognized option'*) selinux_flag= ;; esac
programs=$(list a b c d e)
artifacts=$(fmt "${BUILD_DIR}/%s" ${programs})
lint() {
	run shellcheck ${script_files}
	run shfmt -d ${script_files}
}

while next_target; do
	case "${__target__}" in
	dist | -)
		lint
		run ./nice_modules/nice_things/nice_build.sh
		run shfmt -w ${dist_bin}
		_run diff ./dot-slash-make.sh ${dist_bin}
		;;
	build)
		run ./nice_modules/nice_things/nice_build.sh
		_run diff ./dot-slash-make.sh ${dist_bin}
		run mkdir -p "${BUILD_DIR}"
		run touch ${artifacts}
		;;
	install)
		run install -D ${selinux_flag} -m 755 -t "${PREFIX}/bin" ${artifacts}
		;;
	uninstall)
		run rm -f $(fmt "${PREFIX}/bin/%s" ${programs})
		;;
	clean)
		_run rm -r "${BUILD_DIR}"
		;;
	test)
		_run return 1
		echo "This line is reachable because _run ignores errors! FLAGS=$(to_string ${FLAGS})"
		run return 1
		echo "This line in unreachable"
		;;
	lint)
		lint
		;;
	format)
		run shfmt -w ${script_files}
		;;
	dev-image)
		run podman build -f Containerfile.dev -t ${app_name}-dev
		;;
	# dot-slash-make: This * case must be last and should not be changed
	*) abort "No rule to make target '${__target__}'" ;;
	esac
done
