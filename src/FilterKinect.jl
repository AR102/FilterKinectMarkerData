module FilterKinect
export load_markerdata, save, main

using DataFrames, CSV, FFTW, GLMakie

include("Filebrowser.jl")

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

""" Return an empty MarkerData object with no contents. """
empty_markerdata() = MarkerData([], DataFrames.DataFrame(), DataFrames.DataFrame())

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
function save(data::MarkerData, filepath::String; overwrite=false, filtered = false)
    if !overwrite && (isfile(filepath) || isdir(filepath))
        throw(ArgumentError("$filepath already exists!"))
    end

    first_line = CSV.read(IOBuffer(data.filehead[1]), DataFrame,
        header=false, ignorerepeated=true, # because of possible padding
        delim='\t',
    )
    # if last column has Missing type (can happen with trailing delimiters),
    # then remove it
    if eltype(first_line[!, end]) <: Missing
        first_line = first_line[!, 1:end-1]
    end
    # update last column (filename) to current filename
    first_line[1, end] = splitdir(filepath)[2]

    io = open(filepath, write=true, truncate=true, create=true) do io
        # write updated first line
        CSV.write(io, first_line, writeheader=false, delim='\t')
        # write rest
        for line in data.filehead[2:end]
            write(io, line * "\n")
        end
    end

    df = filtered ? data.filtered_df : data.df
    # append=true to avoid overwriting of file and writing of headers
    CSV.write(filepath, df, append=true, delim='\t')
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

struct FilterConfig
    df::DataFrame
end

function FilterConfig(markernames, optionnames, optiontypes, optionvalues)
    col_names = ["MarkerName", optionnames...]
    cols = [String[], optiontypes...]
    df = DataFrame(cols, col_names)
    for markername in markernames
        push!(df, [markername, optionvalues...])
    end
    return FilterConfig(df)
end

"""
    getrow(df::DataFrame, markername)

Return the row of the given marker (as a view).
"""
function getrow(df::DataFrame, markername)
    # create subset of df containing the one row with the same marker name
    return subset(df, :MarkerName => name -> name .== string(markername),
        view=true) # not a copy, but a reference
end

"""
    getoption(filterconfig::FilterConfig, markername, option)

Return value of option `option` for marker `markername` saved in `filterconfig`.
"""
function getoption(filterconfig::FilterConfig, markername, option)
    row = getrow(filterconfig.df, markername)
    return row[1, option]
end

"""
    setoption(filterconfig::FilterConfig, markername, option, value)

Set option `option` for marker `markername` in `filterconfig` to given `value`.
"""
function setoption(filterconfig::FilterConfig, markername, option, value)
    global row = getrow(filterconfig.df, markername)
    row[1, option] = value
end

save(filterconfig::FilterConfig, path::String) = CSV.write(path, filterconfig.df)

load_filterconfig(path::String) = FilterConfig(CSV.read(path, DataFrame))

function julia_main()::Cint
    global data = Observable(empty_markerdata())
    global filterconfig = Observable(FilterConfig(DataFrames.DataFrame()))
    # x values for plotting, min fft frq possible, max fft frq possible;
    # defined here to bring into scope (see data handler)
    local x, min_possible, max_possible

    @info "Starting UI..."
    #-----------------------------------------------
    #------------------ LAYOUT ---------------------
    #-----------------------------------------------
    fig = Figure()

    # plot for displaying data
    ax = Axis(fig[1:8, 1:5], xlabel="time in s")

    # slider for setting filter range
    slider = IntervalSlider(fig[2, 6:8])
    slider.interval.ignore_equal_values = true

    # labels for showing filter range
    min_value_label = Label(fig[1, 6], "")
    max_value_label = Label(fig[1, 8], "")

    # editable text boxes for setting filter range
    min_value_box = Textbox(fig[3, 6], width=50)
    max_value_box = Textbox(fig[3, 8], width=50)
    # validators make sure that entered value is an Int and in range
    min_value_box.validator = str -> begin
        val = tryparse(Int, str)
        return val !== nothing && validate_min(val, slider, min_possible)
    end
    max_value_box.validator = str -> begin
        val = tryparse(Int, str)
        return val !== nothing && validate_max(val, slider, max_possible)
    end

    # menu for selecting a marker
    marker_menu = Menu(fig[4:8, 6:8], valign=:top,
        # to show more entries on one page to help with too slow scrolling
        fontsize=10, textpadding=(5, 5, 5, 5)
    )

    # Buttons for saving & loading data
    Label(fig[5, 6], "Marker Data", halign=:right)
    savebutton_data = Button(fig[5, 7], label="Save Filtered", fontsize=11, halign=:left)
    loadbutton_data = Button(fig[5, 8], label="Load Raw", fontsize=11, halign=:left)
    Label(fig[6, 6], "Filter Configuration")
    savebutton_config = Button(fig[6, 7], label="Save", fontsize=11, halign=:left)
    loadbutton_config = Button(fig[6, 8], label="Load", fontsize=11, halign=:left)

    #-----------------------------------------------
    #-------------- EVENT HANDLERS -----------------
    #-----------------------------------------------
    # update plots by notifying these Observables
    filtered_plot_update = Observable(nothing)
    raw_plot_update = Observable(nothing)
    # open explorer windows for selecting file and load data from selected file
    on(loadbutton_data.clicks) do _
        path = joinpath(load_dialogue("*.trc")...)
        @info "Loading data..."
        data[] = load_markerdata(path)
        @info "Plotting..."
        notify(raw_plot_update)
        notify(filtered_plot_update)
    end
    # handler for loaded data
    on(data, priority=1000) do data
        x = data.df[!, :Time]
        # ignore first 2 headers as they are Time and Frame
        global markernames = names(data.df)[3:end]

        min_possible = 1
        # see docs rfft: n_fft = div(n,2) + 1
        max_possible = Int(trunc(length(data.df[!, :Time]) / 2) + 1)
        # create `filterconfig` for storing individual filtering options for each
        # marker; this must be before setting marker_menu.i_selected, as that
        # updates filtered_y etc. which need filterconfig
        optionnames = ["MinFrqFFT", "MaxFrqFFT"]
        optiontypes = [Int[], Int[]]
        optionvalues = [min_possible, max_possible]
        filterconfig[] = FilterConfig(markernames, optionnames, optiontypes, optionvalues)

        marker_menu.options[] = zip(markernames, markernames)

        slider.range[] = range(min_possible, max_possible)
        set_close_to!(slider, min_possible, max_possible)
    end

    # Update range of slider when value texboxes are edited
    on(min_value_box.stored_string) do str
        min_val = parse(Int, str)
        _, max_val = slider.interval[]
        set_close_to!(slider, min_val, max_val)
    end
    on(max_value_box.stored_string) do str
        max_val = parse(Int, str)
        min_val, _ = slider.interval[]
        set_close_to!(slider, min_val, max_val)
    end

    # if no marker is selected, select first one
    on(marker_menu.selection, priority=999) do _
        if marker_menu.selection[] === nothing
            marker_menu.i_selected[] = 1
            notify(raw_plot_update)
        end
    end
    # after selecting new marker, update raw data plot + slider interval
    on(marker_menu.selection, priority=-1) do _
        notify(raw_plot_update)
        min_frq = getoption(filterconfig[], marker_menu.selection[], :MinFrqFFT)
        max_frq = getoption(filterconfig[], marker_menu.selection[], :MaxFrqFFT)
        set_close_to!(slider, min_frq, max_frq)
        notify(filtered_plot_update)
    end

    # update labels to always show current slider interval
    on(slider.interval) do (min_frq, max_frq)
        min_value_label.text = string(min_frq)
        max_value_label.text = string(max_frq)
    end
    # update filter config whenever slider is adjusted
    on(slider.interval) do (min_frq, max_frq)
        setoption(filterconfig[], marker_menu.selection[], :MinFrqFFT, min_frq)
        setoption(filterconfig[], marker_menu.selection[], :MaxFrqFFT, max_frq)
        notify(filtered_plot_update)
    end

    on(savebutton_data.clicks) do _
        path = joinpath(save_dialogue("*.trc")...)
        # overwrite because save_dialogue should already warn and ask user about
        # overwrite
        save(data[], path, overwrite=true, filtered=true)
    end
    on(savebutton_config.clicks) do _
        path = joinpath(save_dialogue("*.cfg")...)
        save(filterconfig[], path)
    end
    on(loadbutton_config.clicks) do _
        path = joinpath(load_dialogue("*.cfg")...)
        filterconfig[] = load_filterconfig(path)
        # notify listeners of marker_menu as it also necesitates getting current
        # filter config (for current marker)
        notify(marker_menu.selection)
    end

    display(fig) # show gui
    @info "Please select a .trc file with the motion data!"
    notify(loadbutton_data.clicks) # ask user for inital file

    # draw original data of selected marker
    original_y = lift(raw_plot_update) do _
        data[].df[!, marker_menu.selection[]]
    end
    lines!(ax, x, original_y, label="original data")

    # Draw filtered data of selected marker
    filtered_y = lift(filtered_plot_update) do _
        markername = marker_menu.selection[]
        min_frq = getoption(filterconfig[], markername, :MinFrqFFT)
        max_frq = getoption(filterconfig[], markername, :MaxFrqFFT)
        filter!(data[], markername, min_frq=min_frq[1], max_frq=max_frq)
        return data[].filtered_df[!, markername]
    end
    lines!(ax, x, filtered_y, label="filtered data")
    axislegend(ax) # draw legend
    @info "Done!"
    while true
        sleep(1)
    end
    return 0 # if things finished successfully
end

# path = "test/test_file.trc"
# d = load_markerdata(path)

end