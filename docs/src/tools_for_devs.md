# Tools for developers

## Developer settings file

The bevaviour of this project can be changed for helping developers by using a configuration
file.

This file has to be in the top level of the project folder and be called `dev.jl`.

### Adjusting compilation behaviour

By default, when starting the program, (if it doesn't exist yet) a Julia sysimage is created
by compiling all dependencies and this pacakge itself.

This speeds up the starting process a lot, but the last aspect can be a problem if you're
adjusting the source code of this package as it requires you to always delete the old
JuliaSysimage and then wait 5-10 minutes to compile a new one.

To solve this problem, add the following to the configuration file:

```julia
COMPILE_FILTERKINECT = false
```

Remember to delete the preexisting `JuliaSysimage.so` whenever you change this setting.

### Debugging the tests

During the package tests, temporary files are created for testing saving / loading
functionality and possibly other things.
By default, these files are stored in a /temp/jl_xxxx directory and are automatically
deleted after the tests have been run. 
This can be a problem if you wish to analyze these files.

To solve this problem, you can add the following to the configuration file:

```julia
TESTS_USE_LOCAL_DIR = true
```

## Building the documentation

The documentation is built and published automatically after pushing a new commit to main.

However, a useful tool is the script at `scripts/preview_docs.sh`. It builds the
documentation locally and then uses LiveServer.jl to make it available to you at
http://localhost:8000.

The docs automatically rebuild and the webwebpage refreshes itself whenever you change the
sourcecode of the documentation while the script is running.

This tool is useful because it allows you to preview changes immediately instead of waiting
10 - 20 minutes for GitHub Actions.

To use it, just make sure you're in the project folder and run

```
./scripts/preview_docs.sh
```