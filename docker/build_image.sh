#!/bin/bash
if [ -n "${http_proxy}" ]; then
      all_proxy=${http_proxy} \
      http_proxy=${http_proxy} \
      https_proxy=${http_proxy} \
      DOCKER_BUILDKIT=1 \
      docker build \
            --progress=plain \
            --build-arg http_proxy=${http_proxy} \
            --build-arg https_proxy=${http_proxy} \
            --secret id=passwd,src=./.secret \
            --build-arg UID=$(id -u) \
            --build-arg USER=$(whoami) \
            --build-arg CMAKE_CUDA_ARCHITECTURES=86 \
            -f Dockerfile \
            -t gaussian_splat:latest \
            --network=host \
            . ;
else
      DOCKER_BUILDKIT=1 \
      docker build \
            --progress=plain \
            --secret id=passwd,src=./.secret \
            --build-arg UID=$(id -u) \
            --build-arg USER=$(whoami) \
            --build-arg CMAKE_CUDA_ARCHITECTURES=86 \
            -f Dockerfile \
            -t gaussian_splat:latest \
            --network=host \
            . ;
fi
mkdir -p workspace
mkdir -p .ssh
mkdir -p .vscode .vscode/server_data .vscode/user_data .vscode/extensions
mkdir -p .cache
touch .bash_history
