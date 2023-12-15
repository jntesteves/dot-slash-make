#!/usr/bin/env sh
# SPDX-License-Identifier: Unlicense
# shellcheck disable=SC2046,SC2086
. ./dot-slash-make.sh

param BUILD_DIR=./build
param PREFIX="${HOME}/.local"
app_name=dot-slash-make
script_files=$(wildcard ./*.sh ./make)

for __target in ${__dsm__targets}; do
    case "${__target}" in
        build | -)
            run echo mkdir -p "${BUILD_DIR}"
            run echo touch $(fmt "${BUILD_DIR}/%s" a b c d e)
            ;;
        install)
            run echo install -DZ -m 644 -t "${PREFIX}/bin" ${script_files}
            ;;
        uninstall)
            run echo rm -f $(fmt "${PREFIX}/bin/%s" ${script_files})
            ;;
        clean)
            run_ echo rm -r "${BUILD_DIR}"
            ;;
        test)
            run_ return 1
            run_ echo 'This line is reachable because run_ ignores errors!'
            run return 1
            run echo 'This line in unreachable'
            ;;
        lint)
            run shellcheck ${script_files}
            run shfmt -p -i 4 -ci -d ${script_files}
            ;;
        format)
            run shfmt -p -i 4 -ci -w ${script_files}
            ;;
        dev-image)
            run podman build -f Containerfile.dev -t ${app_name}-dev
            ;;
        # dot-slash-make: This * case must be last and should not be changed
        *) abort "No rule to make target '${__target}'" ;;
    esac
done
