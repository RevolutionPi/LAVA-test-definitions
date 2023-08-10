# Coding style guide

The shell scripts follow [Google's Shell Style
Guide](https://google.github.io/styleguide/shellguide.html). There are some
exceptions.

## Shell

Instead of Bash, POSIX compliant `/bin/sh` is used. The only allowed extension
is the use of the `local` keyword to define local variables.

## File Extension

A shell script should have the file extension `.sh`.

## Logging

Logging is done through `sh-test-lib`'s `error_fatal`, `error_msg`, `warn_msg`,
and `info_msg`.
