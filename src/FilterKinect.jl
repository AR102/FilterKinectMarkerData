module FilterKinect
export load_markerdata, save_markerdata, main

using DataFrames, CSV, FFTW, GLMakie

"""
    get_header_names(path::String)

Return vector of header names as string and the first six lines of the file as
tuple.

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
    # Make MARKERNAME into MARKERNAME_X, MARKERNAME_Y and MARKERNAME_Z for every
    # marker
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
function Base.getproperty(obj::MarkerData, sym::Symbol)
    if sym in [:df, :filehead, :filtered_df]
        getfield(obj, sym)
    else
        getproperty(obj.df, sym)
    end
end

Base.isequal(x::MarkerData, y::MarkerData) =
    x.filehead == y.filehead && x.df == y.df && x.filtered_df == y.filtered_df

Base.copy(d::MarkerData) =
    MarkerData(copy(d.filehead), copy(d.df), copy(d.filtered_df))

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

`overwrite`: If false and the file already exists or it's a folder, an exception
will be thrown. If true, the file gets completely overwritten instead.
The default is false.
"""
function save_markerdata(data::MarkerData, filepath::String; overwrite=false)
    if !overwrite && (isfile(filepath) || isdir(filepath))
        throw(ArgumentError("$filepath already exists!"))
    end
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

Filter column `header_name` of `data` by first calculating a frequency 
representation of the data using FFT and setting every frequency not between 
`min_frq` and `max_frq` (inclusive) to 0.
Then the FFT data is reconstructed into an array of real numbers.

This filtered result is written into the corresponding column of 
data.filtered_df.
"""
function filter!(data::MarkerData, header_name::String; min_frq=1, max_frq=80)
    fft_data = rfft(data.df[!, header_name])

    filtered_fft_data = zeros(eltype(fft_data), length(fft_data))
    # only set frequencies in range, meaning rest stays 0
    filtered_fft_data[min_frq:max_frq] = fft_data[min_frq:max_frq]

    data.filtered_df[!, header_name] = irfft(
        filtered_fft_data, length(data.df[!, header_name])
    )
end


"""
    validate_min(value)

Validate that new minimum frequency for filtering `value` is legal (not bigger
than maximum `slider` currently has and not smaller than `min_possible`).
"""
function validate_min(value, slider, min_possible)
    _, max_value = to_value(slider.interval)
    return min_possible < value <= max_value
end

"""
    validate_max(value)

Validate that new maximum frequency for filtering `value` is legal (not smaller
than minimum `slider` currently has and not bigger than `max_possible`).
"""
function validate_max(value, slider, max_possible)
    min_value, _ = to_value(slider.interval)
    return min_value < value <= max_possible
end

function main(data::MarkerData)
    fig = Figure()
    ax = Axis(fig[1:8, 1:5],
        xlabel="time in s"
    )

    # ignore first 2 headers as they are Time and Frame
    options = zip(names(data.df)[3:end], names(data.df)[3:end])
    marker_menu = Menu(fig[4:8, 6:8], options=options, valign=:top,
        # to show more entries on one page to help with too slow scrolling
        fontsize=10, textpadding=(5, 5, 5, 5)
    )

    # cols = [Int[] for i in eachindex(options)]
    # # String for column "Option"
    # cols = [String, cols...]
    # col_names = ["Option", options[1]...]

    # filterconfig = DataFrame(cols, col_names)

    min_possible = 1
    #              s. docs rfft: n_fft = div(n,2) + 1
    max_possible = Int(trunc(length(data.df[!, :Time]) / 2) + 1)

    # labels for showing filter range
    min_value_label = Label(fig[1, 6], string(min_possible))
    max_value_label = Label(fig[1, 8], string(max_possible))
    # slider for setting filter range
    slider = IntervalSlider(fig[2, 6:8], range=range(min_possible, max_possible))

    # update values of labels whenever slider is adjusted 
    on(slider.interval) do interval
        min_val, max_val = to_value(interval)
        min_value_label.text = string(min_val)
        max_value_label.text = string(max_val)
    end

    # Editable text boxes for setting filter range
    min_value_box = Textbox(fig[3, 6], width=50)
    max_value_box = Textbox(fig[3, 8], width=50)
    # Validators make sure that entered value is an Int and in range
    min_value_box.validator = str -> begin
        val = tryparse(Int, str)
        return val !== nothing && validate_min(val, slider, min_possible)
    end
    max_value_box.validator = str -> begin
        val = tryparse(Int, str)
        return val !== nothing && validate_max(val, slider, max_possible)
    end

    # Update range of slider when value texboxes are edited
    on(min_value_box.stored_string) do str
        min_val = parse(Int, str)
        max_val = to_value(slider.interval)[2]
        set_close_to!(slider, min_val, max_val)
    end
    on(max_value_box.stored_string) do str
        min_val = to_value(slider.interval)[1]
        max_val = parse(Int, str)
        set_close_to!(slider, min_val, max_val)
    end

    x = data.df[!, :Time]

    # Draw original data of selected marker
    original_y = lift(marker_menu.selection) do header
        data.df[!, header]
    end
    lines!(ax, x, original_y, label="original data")

    # Draw filtered data of selected marker
    filtered_y = lift(slider.interval, marker_menu.selection) do interval, header
        filter!(data, header, min_frq=interval[1], max_frq=interval[2])
        return data.filtered_df[!, header]
    end
    lines!(ax, x, filtered_y, label="filtered data")

    axislegend(ax)
    display(fig)
end

end