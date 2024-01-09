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
  * Caveat: this form does not allow tilde expansion `~/` (except on bash, which does tilde expansion when parsing this kind of argument)  
  Prefer using the variable `$HOME` instead of tilde expansion
* Any other arguments not starting with a `-` (dash) are considered targets
* Many targets can be called from a single invocation, f.e. `./make lint build test`

## Usage

dot-slash-make is meant to be vendored (copied) into your repository. Just copy the files [dot-slash-make.sh](dot-slash-make.sh) and [make](make) to your project, and edit the `make` file to include your targets (do not make changes to `dot-slash-make.sh`). Then, in your documentation, replace every instance of `make` with `./make`. That's it! You can delete your old Makefile now, if you haven't yet.

### Included functions

* `$(fmt pattern args…)`: Applies a printf-style format pattern to a list of arguments. Like `printf`, but doesn't print the pattern on empty arguments list
* `$(list args…)`: Turn arguments into a list of items separated by IFS
  * The IFS variable is changed to ASCII control code `0x1F` in dot-slash-make to allow for "quasi-lossless" lists/arrays in pure POSIX shell script. There's almost no risk of accidental field splitting, so quoting variables is not necessary
* `$(list_from string [separator])`: Turn string into a list splitting at each occurrence of separator. If separator isn't provided the default value of IFS is used (space|tab|line-feed)
* `param NAME=VALUE`: Set variable NAME=VALUE, only if it was not overridden by an argument on the CLI (this is the behavior of a variable assignment in GNU Make)
* `run command [args…]`: Evaluate command in a sub-shell, abort on error (equivalent to a normal command in a Makefile)
* `run_ command [args…]`: Evaluate command in a sub-shell, ignore returned status code (equivalent to starting a command line with a `-` in a Makefile)
* `$(wildcard args…)`: Performs globbing on arguments. Similar to GNU Make's [wildcard](https://www.gnu.org/software/make/manual/make.html#Wildcard-Function) function
  * Implicit globbing is disabled in dot-slash-make, as that is safer and easier to use. You must explicitly call this function when you want Pathname Expansion to happen on some text

There is example usage of these functions in the sample [./make](make) file.

### Extra functions

Used internally by dot-slash-make, but exposed publicly because they can be useful.

* `abort`, `log_error`, `log_warn`, `log_info`, `log_debug`, `log_trace`: Logging functions (set `MAKE_DEBUG` to `1` or `trace` to see debug and trace messages)
* `$(escape_single_quotes_builtin text)`: Escape text for use in a shell script single-quoted string (shell builtin version)
* `is_list args…`: Test if any of the arguments is itself a list according to the current value of IFS
* `$(quote_for_eval args…)`: Wrap all arguments in single-quotes and concatenate them separated by spaces, the output escaped appropriately for passing to `eval`
* `$(substitute_character_builtin char replacement text)`: Substitute every instance of character in text with replacement string. This function uses only shell builtins and has no external dependencies (f.e. on `sed`). This is slower than using `sed` on a big input, but faster on many invocations with small inputs
* `validate_var_name text`: Validate if text is appropriate for a shell variable name

## Dependencies

dot-slash-make only needs a POSIX-compatible shell, there are no external dependencies for basic functioning, not even Unix core utilities.

## Contributing

Development of dot-slash-make depends on shellcheck and shfmt. Every change must pass lint and formatting validation with `./make lint`. As an option, formatting can be automatically applied with `./make format`. Optionally, there's a development container image with all the tools required for development pre-installed, it can easily be used with [contr](https://codeberg.org/contr/contr):

```shell
# Build the development image
./make dev-image

# Enter the development container
contr dot-slash-make-dev

# Analyze your changes for correctness
./make lint
```

It is a goal of this project to remain small, in the single-digit kilobytes range. While the code must be terse, it must also be readable and maintainable. Every ambiguous decision and potentially unexpected behavior must have its reasoning documented in accompanying code comments, preferably, and/or in this document, when appropriate.

## Similar projects

* [GNU Make](https://www.gnu.org/software/make/) – The C build system often (ab)used as a command runner
* [just](https://github.com/casey/just) – A command runner inspired by Make

Plus every other software build system offers its own way to save and run commands. But only ./make runs everywhere with zero dependencies, no DSL, in a few kilobytes of shell script.

## License

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

See [UNLICENSE](UNLICENSE) file or http://unlicense.org/ for details.
