# dot-slash-make (./make)

A command runner in a small POSIX shell script meant to replace Make for software that doesn't need it.

## Reasoning behind ./make

Many software projects use GNU Make simply as a command runner, but Make is overkill for this use-case. Make is a build system for C programs, if your software already uses another build system, it shouldn't depend on Make just for running commands. Most OSes don't come with Make pre-installed, so this is yet another dependency people need to install to be able to build/install your software. ./make is a small shell script with zero dependencies, meant to replace a Makefile to remove a dependency on Make where it doesn't make sense.

The reasoning is: if you're using a Makefile just to save some commands you run often, stop! Use a shell script instead, that's the right tool for the job.

./make is simply a standard to make command-running easier across projects, to replace the current "make" standard. The CLI borrows heavily from GNU Make for easy migration.

## Comparison to GNU Make

This repository includes an example [Makefile](Makefile) which is equivalent to the sample [./make](make) file, for comparison. Note how both have similar lengths. Writing a ./make file is not any harder than writing a Makefile.

For most people, writing a ./make file might actually be easier than writing a Makefile. The ./make file is written in shell script, a language many already know, while a Makefile is written in a [DSL](https://en.wikipedia.org/wiki/Domain-specific_language) full of idiosyncrasies few people fully understand (.PHONY? `=` vs `:=`). Shell script also enjoys great tooling to analyze your code, like this repository's use of [shellcheck](https://www.shellcheck.net) and [shfmt](https://github.com/mvdan/sh).

The following CLI behaviors are copied from Make:
* Parameter overrides can be set on the CLI in arguments of the form NAME=VALUE, f.e. `./make install PREFIX=/usr/local`
  * Caveat: this form does not allow Tilde Expansion `~/`, except on bash, which does tilde expansion when parsing this kind of argument. Users on other shells must use the variable `$HOME` instead of Tilde Expansion (this caveat also applies to Make)
* Any other arguments not starting with a `-` (dash) are considered targets
* Many targets can be called from a single invocation, f.e. `./make lint build test`

## Usage

dot-slash-make is meant to be vendored (copied) into your repository. Just copy the files [dot-slash-make.sh](dot-slash-make.sh) and [make](make) to your project, and edit the `make` file to include your targets (do not make changes to `dot-slash-make.sh`). Then, in your documentation, replace every instance of `make` with `./make`. That's it! You can delete your old Makefile now, if you haven't yet.

### Included functions

* `abort`, `log_error`, `log_warn`, `log_info`, `log_debug`, `log_trace`, `log_is_level`: Logging functions (set `MAKE_LOG_LEVEL` to `debug` or `trace` to see debug messages)
* `echo [args…]`: Portable echo that takes no options for consistent behavior across platforms
* `$(fmt pattern args…)`: Apply a printf-style format pattern to a list of arguments. Like `printf`, but doesn't print the pattern on empty arguments list
* `$(list args…)`: Turn arguments into a list of items separated by IFS
  * The IFS variable is changed to ASCII control code `0x1F` in dot-slash-make to allow for "quasi-lossless" lists/arrays in pure POSIX shell script. There's almost no risk of accidental field splitting, so quoting variables is not necessary
* `$(list_from text [separator])`: Turn text into a list splitting at each occurrence of separator. Separator is an optional string containing one or more characters, all of which will be used as separators. If separator isn't provided, the default value of IFS is used (space|tab|line-feed)
* `$(length args…)`: Print the length of the list passed in as arguments
* `$(to_string args…)`: Print a friendly view of the list passed in as arguments
* `param NAME=VALUE`: Set variable NAME=VALUE, only if it was not overridden by an argument on the CLI (this is the behavior of a variable assignment in a Makefile)
* `run command [args…]`: Run command in a sub-shell, abort on error (equivalent to a normal command in a Makefile recipe)
* `_run command [args…]`: Run command in a sub-shell, ignore returned status code (equivalent to starting a command line with a `-` in a Makefile recipe)
* `$(glob args…)`: Perform Pathname Expansion (aka globbing) on arguments
  * Implicit globbing is disabled in dot-slash-make, as that is safer and easier to use. You must explicitly call this function when you want Pathname Expansion to happen on some text
* `$(wildcard args…)`: Like `glob`, but also performs Tilde Expansion. Similar to the [wildcard](https://www.gnu.org/software/make/manual/make.html#Wildcard-Function) function in a Makefile
* `assign var_name command [args…]`: Assign stdout of command to the variable `var_name`, guarding against the loss of trailing line-feed characters that happens on assignments of Command Substitution.

There is example usage of these functions in the sample [./make](make) file.

### Extra functions

Used internally by dot-slash-make, but exposed publicly because they can be useful.

* `assign_variable NAME=VALUE`: Use indirection to dynamically assign a variable from argument NAME=VALUE
* `is_list args…`: Test if any of the arguments is itself a list according to the current value of IFS

## Dependencies

dot-slash-make only needs a POSIX-compatible shell, there are no external dependencies, not even Unix core utilities.

## Contributing

Development of dot-slash-make depends on shellcheck and shfmt. Every change must pass lint and formatting validation with `./make lint`. As an option, formatting can be automatically applied with `./make format`. Optionally, there's a development container image with all the tools required for development pre-installed, it can easily be used with [contr](https://codeberg.org/contr/contr):

```shell
# Build the development image
./make dev-image

# Enter the development container
contr dot-slash-make-dev

# Analyze your changes for correctness
./make lint

# Build ./dist/dot-slash-make.sh
./make
```

## Similar projects

* [GNU Make](https://www.gnu.org/software/make/) – The classic build system often (ab)used as a command runner
* [just](https://github.com/casey/just) – Another command runner inspired by Make

Plus every other software build system offers its own way to save and run commands. But only ./make runs everywhere with zero dependencies, no DSL, in a few kilobytes of portable shell script.

## License

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

See [UNLICENSE](UNLICENSE) file or http://unlicense.org/ for details.
