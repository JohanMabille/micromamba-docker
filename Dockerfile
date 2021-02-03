ARG BASE_IMAGE=debian:buster-slim

# Mutli-stage build to keep final image small. Otherwise end up with
# curl and openssl installed
FROM debian:buster-slim AS stage1
ARG VERSION=0.7.12
RUN apt-get update && apt-get install -y \
    bzip2 \
    ca-certificates \
    curl \
    && rm -rf /var/lib/{apt,dpkg,cache,log}
RUN curl -L https://micromamba.snakepit.net/api/micromamba/linux-64/$VERSION | \
    tar -xj -C /tmp bin/micromamba

FROM $BASE_IMAGE
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV MAMBA_ROOT_PREFIX=/opt/conda

# Use bash in RUN commands and make sure bashrc is sourced when executing commands with /bin/bash -c
# Needed to have the micromamba activate command configured etc.
ENV BASH_ENV ~/.bashrc
SHELL ["/bin/bash", "-c"]

COPY --from=stage1 /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=stage1 /tmp/bin/micromamba /bin/micromamba

RUN ln -s /bin/micromamba /bin/mamba && \
    ln -s /bin/micromamba /bin/conda && \
    ln -s /bin/micromamba /bin/miniconda && \
    mkdir -p $(dirname $MAMBA_ROOT_PREFIX) && \
    /bin/micromamba shell init -s bash -p $MAMBA_ROOT_PREFIX && \
    echo "micromamba activate base" >> ~/.bashrc

CMD ["/bin/bash"]
