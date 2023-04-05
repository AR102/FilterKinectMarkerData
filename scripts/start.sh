# determine name of current directory (not full path)
# https://stackoverflow.com/a/1371283
dirname=${PWD##*/}
dirname=${dirname:-/}

# if current directory is "scripts", then go back up to top-level dir of package
if [ "$dirname" = "scripts" ]; then
    cd ..
fi

# if "JuliaSysimage.*" doesn't exist, then create it
# https://stackoverflow.com/a/6364244
if ! compgen -G "JuliaSysimage.*" > /dev/null; then
    echo "This is the first start, so packages have to be compiled."
    echo "This will take a while. The next start should be faster."
    julia scripts/compile_packages.jl
fi

julia --sysimage JuliaSysimage.so -e "using Pkg; Pkg.activate(\".\"); using FilterKinect; FilterKinect.julia_main()"
