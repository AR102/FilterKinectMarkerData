# Installation

- [Installation](#installation)
  - [1. Install the program](#1-install-the-program)
    - [Option 1](#option-1)
    - [Option 2](#option-2)
  - [2. Install Julia](#2-install-julia)
    - [Ubuntu / Debian](#ubuntu--debian)
      - [**Troubleshooting**](#troubleshooting)
    - [Windows, macOS and other Linux distributions](#windows-macos-and-other-linux-distributions)

## 1. Install the program

### Option 1

Go to https://github.com/AR102/FilterKinect.jl, click on `Code` ⇾ `Local` ⇾ `Download ZIP`.

Extract the archive.

### Option 2

Choose a directory and then use 

```
git clone https://github.com/AR102/FilterKinect.jl`
```

## 2. Install Julia
You can skip this step if the command `julia --version` returns `julia version 1.8.x` or
above. 

If the version is lower, uninstall julia (exact steps depend on how you installed it) and
follow the steps below.

If it returns an error ("command not found" etc.), follow the steps below to install Julia.

### Ubuntu / Debian

1. Open a terminal and go to the desired installation location.
2. Execute `/path/to/FilterKinect.jl/scripts/install-julia_ubuntu.sh`
3. Run `source ~/.bashrc`

Procedure tested on Kubuntu 22.04.

#### **Troubleshooting**

If step 2 returns something like `bash: ./install-julia_ubuntu.sh: Permission denied`, then
first try making the script executable with 

```chmod +x /path/to/FilterKinect/scripts/install-julia_ubuntu.sh```

If this installation script still doesn't work, try a manual installation (see below).

### Windows, macOS and other Linux distributions

See https://julialang.org/downloads/.
