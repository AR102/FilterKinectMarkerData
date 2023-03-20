if ! [ -d "julia-1.8.5" ] ; then
    if ! [ -d "julia-1.8.5-linux-x86_64.tar.gz" ]; then
        # download archive of Julia 1.8.5 if it doesn't exist yet
        wget https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.5-linux-x86_64.tar.gz
    fi
    # extract downloaded archive into julia-1.8.5
    tar zxvf julia-1.8.5-linux-x86_64.tar.gz
fi

# if it hasn't been already, add ./julia-1.8.5/bin to PATH permanently
exportLine="export PATH=\"\$PATH:$PWD/julia-1.8.5/bin/\""
if ! grep -q "$exportLine" ~/.bashrc; then
    echo $exportLine >> ~/.bashrc
fi
# reload bash profile
source ~/.bashrc