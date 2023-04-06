# Tools for developers

## Adjusting compilation behaviour

By default, when starting the program, (if it doesn't exist yet) a Julia sysimage is created
by compiling all dependencies and this pacakge itself.

This speeds up the starting process a lot, but the last aspect can be a problem if you're
adjusting the source code of this package as it requires you to always delete the old
JuliaSysimage and then wait 5-10 minutes to compile a new one.

To solve this problem,
1. Create a file called `dev.jl` in the project folder.
2. Add the following to this file:
```julia
COMPILE_FILTERKINECT = false
```

Remember to delete the preexisting `JuliaSysimage.so` whenever you add this file / line or
remove it.

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