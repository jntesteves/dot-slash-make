#!/usr/bin/env sh
# SPDX-License-Identifier: Unlicense
. ./dot-slash-make.sh

param PREFIX ~/.local

for __target in "$@"; do
    case "$__target" in
        build | '')
            run echo 'Building...'
            ;;
        install)
            run echo 'Installing...' "PREFIX=${PREFIX}"
            ;;
        uninstall)
            run echo 'Uninstalling...' "PREFIX=${PREFIX}"
            ;;
        clean)
            run_ echo 'Cleaning...'
            run_ return 1
            run_ echo 'this line is reachable because run_ ignores errors!'
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
