# based on https://discourse.julialang.org/t/file-picker-for-makie/32295/3
abstract type SysTypes end
struct Windows <: SysTypes end
struct Linux <: SysTypes end

function get_systype()
    if Sys.iswindows()
        return Windows
    end
    if Sys.islinux()
        return Linux
    end
end

# function filebrowser()
#     if Sys.iswindows()
#         return filebrowser(Windows)
#     end
#     if Sys.islinux()
#         return filebrowser(Linux)
#     end
#     throw(ErrorException("Couldn't determine OS! OS is neither Windows nor Linux!"))
# end

#= 
function filebrowser(::Type{Windows})
    filetorun = joinpath(@__DIR__, "../aux_files/fileBrowserWindows.bat")
    filename = String(read(`$filetorun`))
    return splitdir(strip(filename, ['\r', '\n']))
end

function filebrowser(::Type{Linux})
    comm = `zenity --file-selection`
    filename = String(read(comm))
    return splitdir(strip(filename, ['\n']))
end
=#


"""
    check_extension(file::String, extension::String)
    check_extension(file::String, extension::Nothing)

Check if given String `file` ends in `extension`.
"""
function extension_matches(filepath::AbstractString, extension::AbstractString)
    return filepath[end-length(extension)+1:end] == extension
end

function assure_extension(filepath::AbstractString, extension::AbstractString)
    # remove any * from `extension`
    extension = replace(extension, "*" => "")
    if !extension_matches(filepath, extension)
        filepath *= extension
    end
    return filepath
end

assure_extension(filepath::String, extension::Nothing) = filepath

function save_dialogue(::Type{Linux}, extension=nothing)
    if extension === nothing
        arg = ``
    else
        arg = `--file-filter=$extension`
    end
    comm = `zenity --file-selection --save --confirm-overwrite $arg`
    # remove quotes
    cmd = `$comm`
    filepath = String(read(cmd))
    @info filepath
    filepath = strip(filepath)

    filepath = assure_extension(filepath, extension)

    return filepath
end

function load_dialogue(::Type{Linux}, filepattern=nothing)
    if filepattern === nothing
        arg = ``
    else
        arg = `--file-filter=$filepattern`
    end
    comm = `zenity --file-selection $arg`
    # remove quotes
    cmd = `$comm`
    return String(read(cmd))
end

function save_dialogue(extension=nothing)
    filepath = save_dialogue(get_systype(), extension)
    return splitdir(strip(filepath, ['\r', '\n']))
end

function load_dialogue(filepattern=nothing)
    filepath = load_dialogue(get_systype(), filepattern)
    dir, file = splitdir(strip(filepath, ['\r', '\n']))
    # file extension; ignore leading "*"
    # append extension to file if not already there
    if filepattern !== nothing
        extension = filepattern[2:end]
        if !extension_matches(file, extension)
            file *= extension
        end
    end
    return dir, file
end