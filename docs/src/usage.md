# Usage

## Starting

In the top-level directory of the program (`.../FilterKinect.jl/`), run

```
./scripts/start.sh
```

The first start will take a while as the program precompiles packages and saves the produced
system image, but this will significantly speed up following executions.

A file browser should open now. Select the file containing the tracker position data you
want to filter / smooth out (it should have a `.trc` extension) and wait for it to be read.

When it is finished, you should see the values of one axis of a singular marker plotted in
an orange line on the left.

To choose another marker or another axis, use the dropdown menu. The options consist of
`MARKERNAME_AXISNAME`, e.g. `NECK_Y` or `SHOULDER_LEFT_X`.

You should reset the view of the plot (see [Plot controls](@ref)) after choosing a different
marker as this doesn't happen automatically (yet). Otherwise, you may be too far zoomed in
or out to even see the data.

## Filtering

Use the slider at the top to adjust the frequencies allowed through the filter: Slide the
left point of the slider to the right to remove the lower frequencies and slide the right
one to the left to remove the higher frequencies. 

Above the slider on the left side, you can see the current minimum frequency allowed through
the filter and on the right side the maximum frequency.

Use the text field below the slider on the left for entering an exact number as minimum
frequency and the textfield on the right for the maximum freqeuency.

You can see the effect of your adjustments on the left: The blue graph represents the
original data while the orange one represents what it would like filtered with your current
settings.

With the samples tried so far, adjusting the minimum frequency made the data practically
unusable, so it isn't advised.

## Plot controls

| Action     	    | Description                                         	| Shortcut                           	|
|------------	    |-----------------------------------------------------	|------------------------------------	|
| reset view 	    | automatically adjust axes to completely fit the data	| ctrl + double click                	|
| move view  	    | move the view of the plot (without zooming axes) 	  	| hold right click + move mouse     	|
| zoom in    	    | zoom in to current mouse position                   	| mouse wheel up                     	|
| zoom out   	    | zom out from current mouse position                 	| mouse wheel down                   	|
| zoom into window  | zoom into a selected window of the plot           	| hold left click + drag window     	|

## Import / export

Next to the label `Marker Data`, use the button `Save Filtered` to apply the filters and
save the filtered marker position data in a new file, use the button `Load Raw` to load a
different file with position data for filtering.

Use the buttons `Save` and `Load` on the right of the label `Filter Configuration` to save
the current filter configuration and load a new one, respectively.

The filter configuration contains the minimum and maximum frequencies you chose for each
marker.

This can be used to find the correct settings once and then use them for all other motion
files recorded with the same setup without having to manually input them each time.

## Exiting

There are two steps necessary for exiting the program:
1. Close the GUI
2. Use Ctrl + C in the terminal