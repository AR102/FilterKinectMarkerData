if ! [ -d "julia-1.8.5" ] ; then
    if ! [ -d "julia-1.8.5-linux-x86_64.tar.gz" ]; then
        wget https://julialang-s3.julialang.org/bin/linux/x64/1.8/julia-1.8.5-linux-x86_64.tar.gz
    fi
    tar zxvf julia-1.8.5-linux-x86_64.tar.gz
fi

exportLine="export PATH=\"\$PATH:$PWD/julia-1.8.5/bin/\""
if ! grep -q "$exportLine" ~/.bashrc; then
    echo $exportLine >> ~/.bashrc
fi