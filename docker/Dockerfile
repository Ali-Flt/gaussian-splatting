##########################################* CONDA *##########################################
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 as conda_builder
SHELL ["/bin/bash", "--login", "-c"]
COPY --from=continuumio/miniconda3:23.10.0-1 /opt/conda /opt/conda
ENV PATH=/opt/conda/bin:$PATH
ENV TORCH_CUDA_ARCH_LIST="3.5;5.0;6.0;6.1;7.0;7.5;8.0;8.6+PTX"
RUN --mount=type=cache,target=/var/cache/apt,sharing=private \
    --mount=type=cache,target=/var/lib/apt,sharing=private \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache && \
    apt-get update && \
    apt-get install -y --no-install-recommends --reinstall \
    git && \
    cd /root && \
    git clone https://github.com/graphdeco-inria/gaussian-splatting --recursive && \
    cd /root/gaussian-splatting && \
    conda env create --file environment.yml && \
    cd /root && \
    git clone https://github.com/johnowhitaker/tglcourse.git && \
    cd /root/tglcourse && \
    conda run -n gaussian_splatting pip install --no-cache-dir tglcourse
##########################################* FFMPEG *##########################################
FROM ubuntu:20.04 as ffmpeg_builder
SHELL ["/bin/bash", "--login", "-c"]
RUN --mount=type=cache,target=/var/cache/apt,sharing=private \
    --mount=type=cache,target=/var/lib/apt,sharing=private \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache && \
    apt-get update && \
    apt-get install -y --no-install-recommends --reinstall \
    ca-certificates \
    wget \
    xz-utils && \
    cd /root && \
    wget https://johnvansickle.com/ffmpeg/builds/ffmpeg-git-amd64-static.tar.xz -O ffmpeg.tar.xz && \
    tar -xvf ffmpeg.tar.xz
##########################################* VSCODE *##########################################
FROM ubuntu:20.04 as vscode_builder
SHELL ["/bin/bash", "--login", "-c"]
COPY download-vs-code-server.sh /root
RUN --mount=type=cache,target=/var/cache/apt,sharing=private \
    --mount=type=cache,target=/var/lib/apt,sharing=private \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache && \
    apt-get update && \
    apt-get install -y --no-install-recommends --reinstall \
    ca-certificates \
    curl \
    xz-utils && \
    cd /root && \
    chmod a+x download-vs-code-server.sh && \
    ./download-vs-code-server.sh alpine
ENV PATH=/root/.vscode-server/default_version:$PATH
##########################################* FINAL IMAGE *##########################################
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04 as gaussian-splat
ARG USER
ARG UID=1000
ARG CODE_SERVER_PORT=8888
ARG CMAKE_CUDA_ARCHITECTURES=86
ENV DEBIAN_FRONTEND noninteractive
ENV TZ=UTC
ENV CODE_SERVER_PORT ${CODE_SERVER_PORT}
ENV USER ${USER}
ENV CMAKE_CUDA_ARCHITECTURES ${CMAKE_CUDA_ARCHITECTURES}
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
SHELL ["/bin/bash", "--login", "-c"]
RUN echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
RUN --mount=type=cache,target=/var/cache/apt,sharing=private \
    --mount=type=cache,target=/var/lib/apt,sharing=private \
    --mount=type=secret,id=passwd,target=/root/.secret \
    rm -f /etc/apt/apt.conf.d/docker-clean && \
    echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache && \
    apt-get update && \
    apt-get install -y --no-install-recommends --reinstall \
    ca-certificates \
    wget \
    sudo \
    curl \
    tree \
    vim \
    libglew-dev \
    libassimp-dev \
    libboost-all-dev \
    libgtk-3-dev \
    libopencv-dev \
    libglfw3-dev \
    libavdevice-dev \
    libavcodec-dev \
    libeigen3-dev \
    libxxf86vm-dev \
    libembree-dev \
    libboost-program-options-dev \
    libboost-filesystem-dev \
    libboost-graph-dev \
    libboost-system-dev \
    libflann-dev \
    libfreeimage-dev \
    libmetis-dev \
    libgoogle-glog-dev \
    libgtest-dev \
    libsqlite3-dev \
    qtbase5-dev \
    libqt5opengl5-dev \
    libcgal-dev \
    libceres-dev \
    gcc-10 \
    g++-10 \
    cmake \
    build-essential \
    ninja-build \
    git && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    # add user
    useradd -rm -d /home/$USER -s /bin/bash -g root -G sudo -u $UID $USER && \
    echo "$USER:$(cat /root/.secret)" | chpasswd && \
    echo "$USER ALL=(ALL:ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    # install imagemagick
    t=$(mktemp) && \
    wget 'https://dist.1-2.dev/imei.sh' -qO "$t" && \
    bash "$t" && \
    rm "$t"
COPY --from=ffmpeg_builder --chown=$USER:root /root/ffmpeg*/ff* /usr/bin/
COPY --from=vscode_builder --chown=$USER:root /root/.vscode-server/default_version/code /usr/bin/code
COPY --from=conda_builder --chown=$USER:root /opt/conda /opt/conda
ENV PATH=/opt/conda/bin:$PATH
USER $USER
RUN export CC=/usr/bin/gcc-10 && \
    export CXX=/usr/bin/g++-10 && \
    export CUDAHOSTCXX=/usr/bin/g++-10 && \
    mkdir -p /home/$USER/workspace/ && \
    cd /home/$USER/workspace/ && \
    git clone https://github.com/colmap/colmap.git && \
    cd colmap && \
    mkdir build && \
    cd build && \
    cmake .. -GNinja -DCMAKE_CUDA_ARCHITECTURES=$CMAKE_CUDA_ARCHITECTURES && \
    ninja && \
    sudo ninja install
WORKDIR /home/$USER

CMD code serve-web \
    --accept-server-license-terms \
    --without-connection-token \
    --host 0.0.0.0 \
    --port $CODE_SERVER_PORT \
    --server-data-dir /home/$USER/.vscode/server_data \
    --user-data-dir /home/$USER/.vscode/user_data \
    --extensions-dir /home/$USER/.vscode/extensions \
    --cli-data-dir /home/$USER/.vscode/
