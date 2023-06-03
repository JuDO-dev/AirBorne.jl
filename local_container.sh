PROJECT_NAME=airborne

docker build  -t ${PROJECT_NAME}-image   .

#####################################
####   Commands for Windows OS   ####
#####################################

# Run container on Windows with SSH connection to GitHub already configured
winpty docker run --rm -it \
--env-file ./.env \
--mount type=bind,source="$(PWD)",target=/root/AirBorne \
--mount type=bind,source="$HOME/.ssh",target=/root/.ssh \
--mount  type=bind,source="$HOME/.gitconfig",target=/root/.gitconfig \
--name ${PROJECT_NAME}-container \
-p 8080:8080 \
-p 8000:8000 \
--entrypoint bash \
${PROJECT_NAME}-image 

winpty docker exec -it ${PROJECT_NAME}-container bash
