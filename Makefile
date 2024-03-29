run:
	julia --project=./test --color=yes test/runtests.jl

local:
	julia --project=./dev_project ./dev_project/local.jl

dev:
	julia --project=./dev_project 

J:
	julia --project=../AirBorne

testJ:
	julia --project=./test
 
docJ:
	julia --project=./docs

doc:
	julia --project=./docs -e 'using Pkg; Pkg.develop(path="../AirBorne")' 
	julia --project=./docs -e 'using Pkg; Pkg.instantiate()' 
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

lint-fix:
	julia --project=./dev_project -e 'using JuliaFormatter;  format(".")' 
	
lint-fix-local:
	julia --project=./dev_project -e 'using JuliaFormatter;  format("/root/AirBorne/src/Backtest/strategies/SMA.jl", BlueStyle())' 

lint:
	julia --project=./dev_project ./dev_project/lint_test.jl