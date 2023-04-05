# Future development -- Plans

See the [issues page](https://github.com/AR102/FilterKinect.jl/issues) and the
[project board](https://github.com/users/AR102/projects/4) for more up-to-date
information.
## New Features / additions

- description and explanation of the algorithm used for filtering at

## Known Problems

### Tests On Windows

Currently, automated tests over GitHub Actions aren't run on Windows.
This is because the default Windows image on GitHub Actions doesn't have the
necessary display drivers to compile GLMakie.

On Linux, this was easily fixed by installing drivers through apt.
Maybe [winget](https://de.wikipedia.org/wiki/Windows_Package_Manager) could be
used?

### Scrolling Speed In Menu

The menu for selecting the marker to use is very hard to use as scrolling is
extremely slow.

This is an issue in Makie.jl and should hopefully be resolved soon, see
https://github.com/MakieOrg/Makie.jl/pull/2616.
