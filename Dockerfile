FROM debian:bullseye-slim AS binary

LABEL authors="Erik Garrison, Simon Heumos, Andrea Guarracino"
LABEL description="Preliminary docker image containing all requirements for pggb pipeline"
LABEL base_image="debian:bullseye-slim"
LABEL software="pggb"
LABEL about.home="https://github.com/pangenome/pggb"
LABEL about.license="SPDX:MIT"

# odgi's dependencies
RUN apt-get update \
    && apt-get install -y \
                       git \
                       bash \
                       cmake \
                       make \
                       g++ \
                       python3-dev \
                       bc \
                       libatomic-ops-dev \
                       autoconf \
                       libgsl-dev \
                       zlib1g-dev \
                       libzstd-dev \
                       libjemalloc-dev \
                       build-essential \
                       time \
                       curl \
                       pigz
                        
RUN git clone --recursive https://github.com/ekg/wfmash \
    && cd wfmash \
    && git pull \
    && git checkout e4d0c0c \
    && git submodule update --init --recursive \
    && sed -i 's/-mcx16 //g' CMakeLists.txt \
    && sed -i 's/-march=native //g' CMakeLists.txt \
    && sed -i 's/-mcx16 //g' src/common/wflign/CMakeLists.txt \
    && sed -i 's/-march=native //g' src/common/wflign/CMakeLists.txt \
    && sed -i 's/-mcx16 //g' src/common/wflign/deps/WFAv2/CMakeLists.txt \
    && sed -i 's/-march=native //g' src/common/wflign/deps/WFAv2/CMakeLists.txt \
    && sed -i 's/-mcx16 //g' src/common/wflign/deps/wflambdav2/CMakeLists.txt \
    && sed -i 's/-march=native //g' src/common/wflign/deps/wflambdav2/CMakeLists.txt \
    && cmake -H. -Bbuild && cmake --build build -- -j $(nproc) \
    && cp build/bin/wfmash /usr/local/bin/wfmash \
    && cd ../

RUN git clone --recursive https://github.com/ekg/seqwish \
    && cd seqwish \
    && git pull \
    && git checkout 6da2102 \
    && git submodule update --init --recursive \
    && cmake -H. -Bbuild && cmake --build build -- -j $(nproc) \
    && cp bin/seqwish /usr/local/bin/seqwish \
    && cd ../

RUN git clone --recursive https://github.com/ekg/smoothxg \
    && cd smoothxg \
    && git pull \
    && git checkout 9ad1d76 \
    && git submodule update --init --recursive \
    && sed -i 's/-march=native/-march=haswell/g' deps/abPOA/CMakeLists.txt \
    && sed -i 's/-mcx16 //g' deps/WFA/CMakeLists.txt \
    && sed -i 's/-march=native //g' deps/WFA/CMakeLists.txt \
    && cmake -H. -Bbuild && cmake --build build -- -j $(nproc) \
    && cp bin/smoothxg /usr/local/bin/smoothxg \
    && cp deps/odgi/bin/odgi /usr/local/bin/odgi

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y

RUN git clone https://github.com/chfi/rs-handlegraph.git \
    && cd rs-handlegraph \
    && git pull \
    && git checkout 03af2ea \
    && cd - \
    && cargo build --manifest-path rs-handlegraph/Cargo.toml --release \
    && git clone https://github.com/marschall-lab/GFAffix.git \
    && cd GFAffix \
    && git pull \
    && git checkout a0d504a \
    && cargo install --force --path .

RUN apt-get update && apt-get install -y pip && pip install multiqc

RUN apt-get install wget && wget https://github.com/vgteam/vg/releases/download/v1.33.0/vg && chmod +x vg && cp vg /usr/local/bin/vg

COPY pggb /usr/local/bin/pggb
RUN chmod 777 /usr/local/bin/pggb

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
