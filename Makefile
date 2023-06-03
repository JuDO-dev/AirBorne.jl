run:
	julia --project=./project ./test/runtests.jl 

dev:
	julia --project=./dev_project 

julia:
	cd /root & julia --project=./AirBorne

juliaDoc:
	julia --project=./docs

sync:
	julia --project=./project -e 'using Pkg; Pkg.instantiate()'

pluto:
	julia --project=./dev_project ./dev_project/launch_pluto.jl

setgit:
	git config --global user.email ${GITHUB_EMAIL}
	git config --global user.name ${GITHUB_NAME}
	git config --global github.user ${GITHUB_USERNAME}
	git config --global credential.helper store