run:
	julia --project=./project ./test/runtests.jl 

dev:
	julia --project=./dev_project 

julia:
	cd /root & julia --project=./AirBorne

juliaDoc:
	julia --project=./docs

doc:
	julia --project=./docs ./docs/make.jl

docDeploy:
	julia --project=./dev_project  -e 'using LiveServer; serve(dir="docs/build",port=8000,host="0.0.0.0")'
	
sync:
	julia --project=./project -e 'using Pkg; Pkg.instantiate()'

pluto:
	julia --project=./dev_project ./dev_project/launch_pluto.jl

setgit:
	git config --global user.email ${GITHUB_EMAIL}
	git config --global user.name ${GITHUB_NAME}
	git config --global github.user ${GITHUB_USERNAME}
	git config --global credential.helper store