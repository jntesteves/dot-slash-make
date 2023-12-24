#!/usr/bin/env sh
# shellcheck disable=SC2046,SC2086
. ./dot-slash-make.sh

param BUILD_DIR=./build
param PREFIX="${HOME}/.local"
app_name=dot-slash-make
script_files=$(wildcard ./*.sh ./make)
selinux_flag=-Z
# In sh we can detect if the SELinux flag is supported instead of requiring a CLI parameter
case $(install -Z 2>&1) in *'unrecognized option'*) selinux_flag='' ;; esac
programs='a b c d e'
artifacts=$(fmt "${BUILD_DIR}/%s" ${programs})

for __target in ${__dsm__targets}; do
	case "${__target}" in
	build | -)
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
		run_ rm -r "${BUILD_DIR}"
		;;
	test)
		run_ return 1
		run_ echo 'This line is reachable because run_ ignores errors!'
		run return 1
		run echo 'This line in unreachable'
		;;
	lint)
		run shellcheck ${script_files}
		run shfmt -d ${script_files}
		;;
	format)
		run shfmt -w ${script_files}
		;;
	dev-image)
		run podman build -f Containerfile.dev -t ${app_name}-dev
		;;
	# dot-slash-make: This * case must be last and should not be changed
	*) abort "No rule to make target '${__target}'" ;;
	esac
done
