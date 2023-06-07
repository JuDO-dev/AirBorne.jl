using Pkg:Pkg
using Logging 

@info(@__DIR__)
dst_dir=joinpath(@__DIR__,"temp","lint") # Reference directory where linted files are to be stored
src_dir=joinpath(@__DIR__,"..","src") # Relative reference to source files

@info(joinpath(@__DIR__,"..","src"))
@info(isdir(src_dir))
# mkpath(dst_dir)
# cp(src_dir,dst_dir;recursive=true)
for (root, dirs, files) in walkdir(src_dir)
    # mkpath
    # @info(root=
    # @info(root[length(src_dir)+2:end])
    relpath=lstrip( replace(root,src_dir => "" ),['/'])
    mkpath(joinpath(dst_dir,relpath))
    
    for file=files
        println(joinpath.(root, file)) # files is a Vector{String}, can be empty
    end
end