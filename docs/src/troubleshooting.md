# Troubleshooting

## GLMakie not compiling

If you are on a Linux system, you could get an error like 

```
libGL error: MESA-LOADER: failed to open iris: /usr/lib/dri/iris_dri.so: cannot open shared object file: No such file or directory (search paths /usr/lib/x86_64-linux-gnu/dri:\$${ORIGIN}/dri:/usr/lib/dri, suffix _dri)
libGL error: failed to load driver: iris
libGL error: MESA-LOADER: failed to open iris: /usr/lib/dri/iris_dri.so: cannot open shared object file: No such file or directory (search paths /usr/lib/x86_64-linux-gnu/dri:\$${ORIGIN}/dri:/usr/lib/dri, suffix _dri)
libGL error: failed to load driver: iris
libGL error: MESA-LOADER: failed to open swrast: /usr/lib/dri/swrast_dri.so: cannot open shared object file: No such file or directory (search paths /usr/lib/x86_64-linux-gnu/dri:\$${ORIGIN}/dri:/usr/lib/dri, suffix _dri)
libGL error: failed to load driver: swrast
ERROR: GLFWError (VERSION_UNAVAILABLE): GLX: Failed to create context: GLXBadFBConfig
```

This can be resolved by running `export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6` before starting Julia (you may need to replace the path depending on where libstdc++.so.6 is located on your system).

~~For a more permanent solution, see https://github.com/JuliaGL/GLFW.jl/issues/198#issuecomment-1141056514.~~

If you use VSCode, you can add the line
```
"julia.persistentSession.shell": "export LD_PRELOAD=/usr/lib/x86_64-linux-gnu/libstdc++.so.6 /bin/sh"
```
to your settings.
Related links:
- https://github.com/JuliaGL/GLFW.jl/issues/211
- https://github.com/JuliaGL/GLFW.jl/issues/198#issuecomment-740124490
- https://github.com/MakieOrg/Makie.jl/tree/master/GLMakie#troubleshooting-opengl