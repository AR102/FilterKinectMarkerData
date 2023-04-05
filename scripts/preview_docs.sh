# determine name of current directory (not full path)
# https://stackoverflow.com/a/1371283
dirname=${PWD##*/}
dirname=${dirname:-/}

# if current directory is "scripts", then go back up to top-level dir of package
if [ "$dirname" = "scripts" ]; then
    cd ..
fi

# using https://github.com/tlienart/LiveServer.jl/#serve-docs
julia --project=docs -e 'using FilterKinect, LiveServer; servedocs()'