#!/usr/bin/env sh
# SPDX-License-Identifier: Unlicense
. ./dot-slash-make.sh

param BUILD_DIR=./build
param PREFIX="${HOME}/.local"

for __target in ${__targets}; do
    case "${__target}" in
        build | -)
            run echo build-command "${BUILD_DIR}"
            ;;
        install)
            run echo install-command "${PREFIX}"
            ;;
        uninstall)
            run echo uninstall-command "${PREFIX}"
            ;;
        clean)
            run_ echo clean-command "${BUILD_DIR}"
            run_ return 1
            run_ echo 'This line is reachable because run_ ignores errors!'
            run return 1
            run echo 'This line in unreachable'
            ;;
        lint)
            run shellcheck ./*.sh make
            run shfmt -p -i 4 -ci -d ./*.sh make
            ;;
        format)
            run shfmt -p -i 4 -ci -w ./*.sh make
            ;;
        dev-image)
            run podman build -f Containerfile.dev -t dot-slash-make-dev
            ;;
        # dot-slash-make: This * case must be last and should not be changed
        *) abort "No rule to make target '${__target}'" ;;
    esac
done
