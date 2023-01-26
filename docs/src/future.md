# Future Development
## New Features

## Known Problems

### Tests On Windows

Currently, automated tests over GitHub Actions aren't run on Windows.
This is because the default Windows image on GitHub Actions doesn't have the necessary display drivers to compile GLMakie.

On Linux, this was easily fixed by installing drivers through apt.
Maybe [winget](https://de.wikipedia.org/wiki/Windows_Package_Manager) could be used?