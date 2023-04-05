# Tools for developers

## Building the documentation

The documentation is built and published automatically after pushing a new
commit to main.

However, a useful tool is the script at `scripts/preview_docs.sh`. It builds
the documentation locally and then uses LiveServer.jl to make it available to
you at http://localhost:8000.

The docs automatically rebuild and the webwebpage refreshes itself whenever you
change the sourcecode of the documentation while the script is running.

This tool is useful because it allows you to preview changes immediately instead
of waiting 10 - 20 minutes for GitHub Actions.

To use it, just make sure you're in the project folder and run

```
./scripts/preview_docs.sh
```