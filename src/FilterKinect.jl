module FilterKinect
export load_markerdata, save_markerdata, main

using DataFrames, CSV, FFTW, GLMakie

"""
    get_header_names(path::String)

Return vector of header names as string and the first six lines of the file as tuple.

Example:

```julia
julia> get_header_names("my_file.trc")[1]
98-element Vector{String}:
 "Frame"
 "Time"
 "PELVIS_X"
 "PELVIS_Y"
 "PELVIS_Z"
 "SPINE_NAVAL_X"
 "SPINE_NAVAL_Y"
 "SPINE_NAVAL_Z"
 ⋮
 "EAR_LEFT_Z"
 "EYE_RIGHT_X"
 "EYE_RIGHT_Y"
 "EYE_RIGHT_Z"
 "EAR_RIGHT_X"
 "EAR_RIGHT_Y"
 "EAR_RIGHT_Z"
```
"""
function get_header_names(path::String)
    filehead = Vector{String}(undef, 6)
    io = open(path) do io
        for i in 1:6
            filehead[i] = readline(io)
        end
    end
    # forth line contains marker names
    marker_str = filehead[4]
    # remove "Frame#\tTime\t" at beginning
    marker_str = marker_str[13:end]
    marker_names = split(marker_str, "\t\t\t")
    # remove "\t\t" at end of last element
    marker_names[end] = chop(marker_names[end]; tail=2)
    # Frame + Time + 3 cols (X,Y,Z) for each marker
    num_headers = 2 + length(marker_names) * 3
    header_names = Array{String}(undef, num_headers)
    header_names[1:2] = ["Frame", "Time"]

    i = 3 # because of Frame and Time
    # Make MARKERNAME into MARKERNAME_X, MARKERNAME_Y and MARKERNAME_Z for every marker
    for name in marker_names
        for appendix in ["_X", "_Y", "_Z"]
            header_names[i] = name * appendix
            i += 1
        end
    end
    return header_names, filehead
end

struct MarkerData
    filehead::Vector{String}
    df::DataFrame
    filtered_df::DataFrame
end

# Overload MarkerData to redirect getproperty to df
Base.getproperty(obj::MarkerData, sym::Symbol) =
    sym in [:df, :filehead, :filtered_df] ? getfield(obj, sym) : getproperty(obj.df, sym)

Base.isequal(x::MarkerData, y::MarkerData) =
    x.filehead == y.filehead && x.df == y.df && x.filtered_df == y.filtered_df

Base.copy(d::MarkerData) = MarkerData(copy(d.filehead), copy(d.df), copy(d.filtered_df))

"""
    load_marker_data(path::String)

Load coordinate data from a .trc file. Return a `ModelData` object.
"""
function load_markerdata(path::String)
    df = CSV.read(path, DataFrame,
        skipto=7, # ignore first six lines
        header=false # we'll provide our own later
    )
    header_names, filehead = get_header_names(path)
    rename!(df, header_names)
    return MarkerData(filehead, df, copy(df))
end

"""
    save_markerdata(data::MarkerData, filepath::String; overwrite = false)

Save `data` in file at `filepath`. 

`overwrite`: If false and the file already exists or it's a folder,
an exception will be thrown. If true, the file gets completely overwritten instead.
The default is false.
"""
function save_markerdata(data::MarkerData, filepath::String; overwrite=false)
    !overwrite && (isfile(filepath) || isdir(filepath)) ? throw(ArgumentError("$filepath already exists!")) :
    io = open(filepath, write=true, truncate=true, create=true) do io
        for line in data.filehead
            write(io, line * "\n")
        end
    end
    # append=true to avoid overwriting of file and writing of headers
    CSV.write(filepath, data.df, append=true, delim='\t')
end

"""
    filter!(data::MarkerData, header_name::String; min_frq=1, max_frq=80)

Filter column `header_name` of `data` by first calculating a frequency representation 
of the data using FFT and setting every frequency not between `min_frq` and `max_frq` (inclusive)
to 0.
Then the FFT data is reconstructed into an array of real numbers.

This filtered result is written into the corresponding column of data.filtered_df.
"""
function filter!(data::MarkerData, header_name::String; min_frq=1, max_frq=80)
    fft_data = rfft(data.df[!, header_name])

    filtered_fft_data = zeros(eltype(fft_data), length(fft_data))
    # only set frequencies in range, meaning rest stays 0
    filtered_fft_data[min_frq:max_frq] = fft_data[min_frq:max_frq]

    data.filtered_df[!, header_name] = irfft(filtered_fft_data, length(data.df[!, header_name]))
end

function main(data::MarkerData)
    f = Figure()
    ax = Axis(f[1, 1],
        title="Test",
        xlabel="time in s",
        ylabel="?"
    )
    header = "HEAD_X"
    x = data.df[!, :Time]
    y = data.df[!, header]
    lines!(ax, x, y)
    display(f)
end

end