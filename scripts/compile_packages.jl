# inspiration from
# https://github.com/julia-vscode/julia-vscode/blob/main/scripts/tasks/task_compileenv.jl

# get the last part of current directory, i.e. if active dir is 
# /home/x/FilterKinect.jl/scripts, then dir = "scripts"
dir = splitdir(pwd())[2]
# if in .../FilterKinect.jl/scripts (because called by another script), then go
# back to main dir
if dir == "scripts"
    cd("..")
end

import Pkg
Pkg.activate("scripts/CompileEnv")
Pkg.instantiate()

import Libdl, PackageCompiler
PackageCompiler.create_sysimage(sysimage_path="JuliaSysimage.$(Libdl.dlext)", project=".")