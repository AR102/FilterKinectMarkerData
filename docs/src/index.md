```@meta
CurrentModule = FilterKinect
```

# FilterKinect
- [Installation -- Method 1](#installation----method-1)
  - [1. Install Julia](#1-install-julia)
    - [Troubleshooting](#troubleshooting)


Table of Contents:


Documentation for [FilterKinect](https://github.com/AR102/FilterKinect.jl).


## Installation -- Method 1
### 1. Install Julia
You can skip this step if the bash command `julia --version` returns `julia
version 1.8.x` or above. 

If the version is lower, uninstall julia (exact steps depend on how you
installed it) and follow the steps below.

If it returns an error ("command not found" etc.), follow the steps below to
install Julia.

1. Open a terminal and go to the desired installation location.
2. Execute `/path/to/FilterKinect/scripts/install-julia_ubuntu.sh`

#### Troubleshooting

If step 2 returns something like `bash: ./install-julia_ubuntu.sh: Permission
denied`, then first try making the script executable with 

```chmod +x /path/to/FilterKinect/scripts/install-julia_ubuntu.sh```

```@index
```

```@autodocs
Modules = [FilterKinect]
```