import Pkg

"""
Whether to compile not only dependencies but this package itself as well. 
Set to false if you're working on the source code to prevent having to recompile
everything every time you change the code of this project.
"""
COMPILE_FILTERKINECT::Bool = true

# get the last part of current directory, i.e. if active dir is 
# /home/x/FilterKinect.jl/scripts, then dir = "scripts"
dir = splitdir(pwd())[2]
# if in .../FilterKinect.jl/scripts (because called by another script), then go
# back to main dir
if dir == "scripts"
    cd("..")
end

# read information stored in Project.toml about dependencies, project name, etc.
project = Pkg.API.read_project("Project.toml")

# really make sure we're in the right directory
if project.name != "FilterKinect"
    throw(ArgumentError(
        "Wrong directory! You must be in the top-level directory of the project 
        (.../FilterKinect.jl/)"))
end

# if it exists, execute contents of "dev.jl"
# joinpath necessary because include uses location of executed file as base for
# relative paths, not the current working directory, see
# https://github.com/JuliaLang/julia/issues/11755#issuecomment-113281084
isfile("dev.jl") && include(joinpath(pwd(), "dev.jl"))

Pkg.activate("scripts/CompileEnv")
Pkg.instantiate()

# https://github.com/julia-vscode/julia-vscode/blob/main/scripts/tasks/task_compileenv.jl
import Libdl, PackageCompiler

# put dependencies of project into list of packages to be compiled
used_packages = Symbol.(collect(keys(project.deps)))
# add the project itself as well if COMPILE_FILTERKINECT is true
COMPILE_FILTERKINECT && push!(used_packages, Symbol(project.name))

println(used_packages)
PackageCompiler.create_sysimage(used_packages, sysimage_path="JuliaSysimage.$(Libdl.dlext)", project=".")