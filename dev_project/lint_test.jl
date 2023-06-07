using Pkg:Pkg
using Logging 
using DeepDiffs: deepdiff, added, removed
using JuliaFormatter

dst_dir=joinpath(@__DIR__,"temp","lint","src") # Reference directory where linted files are to be stored
src_dir=joinpath(@__DIR__,"..","src") # Relative reference to source files

# Copy Files
@info("Copying files into temporary directory")
for (root, dirs, files) in walkdir(src_dir)
    relpath=lstrip( replace(root,src_dir => "" ),['/'])
    mkpath(joinpath(dst_dir,relpath))
    for file=files
        src=joinpath(src_dir,relpath, file)
        dst=joinpath(dst_dir,relpath, file)
        @info(src* "->"*dst)
        cp(src,dst;force=true)
    end
end

# Copy Configuration
cp(joinpath(@__DIR__,"..",".JuliaFormatter.toml"),joinpath(@__DIR__,"temp","lint",".JuliaFormatter.toml"),force=true)

# Apply Configuration in test folder
@info("Formatting copied Files")
JuliaFormatter.format(joinpath(@__DIR__,"temp","lint"))

# Check the changes made by JuliaFormatter (I couldn't find a way to display as nicely as the console)
# In the meantime simply run the JuliaFormatter and check the git differences. Not ideal but good enough.
# Make sure to commit the files before running the JuliaFormatter otherwise you may not see anything.
@info("Testing if files are identical, if not a message with bash commands will appear to preview the changes on each file.")
const  num_files_affected = Ref(0)
for (root, dirs, files) in walkdir(src_dir)
    relpath=lstrip( replace(root,src_dir => "" ),['/'])
    for file=files
        src=String(read(open(joinpath(src_dir,relpath, file),"r")))
        dst=String(read(open(joinpath(dst_dir,relpath, file),"r")))
        diff=deepdiff(src,dst)
        if (size(added(diff),1)>0) || (size(removed(diff),1)>0) 
            num_files_affected.x += 1
            @info("diff --color '"*joinpath(src_dir,relpath, file)*"' '"*joinpath(dst_dir,relpath, file)*"'")
        end
    end
end
@info("Files_affected $(num_files_affected.x)")