# dot-slash-make

A command runner in a small POSIX shell script meant to replace Make for software that don't need it.

## Why use dot-slash-make

Many software projects use GNU Make simply as a command runner, but Make is overkill for this use-case. Make is a build system for C programs, if your software is not written in C, or if it already uses another build system, it shouldn't be depending on Make just for running commands. Most OSes don't come with Make pre-installed, so this is yet another dependency people need to install to be able to build/install your software. dot-slash-make is a small shell script with zero dependencies, meant to replace your Makefile to remove your dependency on Make.

The reasoning is: if you're using Make just to save and run some commands, stop! Use a shell script instead, that's the right tool for the job.

dot-slash-make is simply a standard to make that easier across projects, to replace the "Makefile-standard". The CLI borrows heavily from GNU Make for easy migration.

### Comparison to GNU Make

This repository includes an example [Makefile](Makefile) which is equivalent to the example [./make](make) file, for comparison. Note how both have similar lengths. Writing a ./make file is not any harder than writing a Makefile.

Actually, writing a ./make file might be easier for you than writing a Makefile. The ./make file is written in shell script, a language you might already know, while a Makefile is written in a [DSL](https://en.wikipedia.org/wiki/Domain-specific_language) full of idiosyncrasies few people fully understand (.PHONY? `=` vs `:=`).

The following CLI behaviors were copied from Make:
* Variables can be set in arguments of the form NAME=VALUE. Ex.: `./make install PREFIX=/local`
* Any other arguments not starting with a `-` (dash) are considered targets (AKA recipes)
* Many targets can be called from a single invocation. Ex.: `./make lint build test`

## Usage

dot-slash-make is meant to be vendored (copied) into your repository. Just copy the files [dot-slash-make.sh](dot-slash-make.sh) and [make](make) to your project, and edit the `make` file to include your targets (do not make changes to `dot-slash-make.sh`). Then, on your documentation, replace every instance of `make` with `./make`. That's it! You can delete your old Makefile now, if you haven't yet.

### Available functions

`run`: Evaluate command in a sub-shell, abort on error (equivalent to a normal command in a Make recipe)  
`run_`: Evaluate command in a sub-shell, ignore returned status code (equivalent to starting a line with a `-` in Make)  
`log_error`, `log_info`, `log_debug`, `abort`: Logging functions (set `BUILD_DEBUG=1` for debug messages)

## Dependencies
dot-slash-make only needs a POSIX-compatible shell, there are no external dependencies, not even Unix core utilities.

## Contributing
To develop dot-slash-make we depend on shellcheck and shfmt. Every change must pass lint and formatting validation with `./make lint`. As an option, formatting can be automatically applied with `./make format`. Optionally, we have a development container image with all the tools required for development pre-installed, it can easily be used with [contr](https://codeberg.org/contr/contr):

```shell
# Build the development image
./make dev-image

# Enter the development container
contr dot-slash-make-dev

# Validate your changes for correctness
./make lint
```

## Similar projects

Compared to these, dot-slash-make has the advantages of being much smaller, having zero dependencies, and being shell script, a language you already know, instead of yet another DSL.

* [GNU Make](https://www.gnu.org/software/make/) – The C build system often (ab)used as a command runner
* [just](https://github.com/casey/just) – A command runner inspired by Make, written in Rust

## License
This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

See [UNLICENSE](UNLICENSE) file or http://unlicense.org/ for details.
