# Build with:
# docker build -t mk_build . --squash
#
# Retrieve build files with:
#   docker run -it mk_build
# then open a new terminal:
#   docker container list
#   docker cp <container_id>:/mk/mk-2024.0-toolchain.tar.gz .
#   docker cp <container_id>:/mk/mk-2024.0-base.tar.gz .
#   docker cp <container_id>:/mk/mk-2024.0-lifex.tar.gz .
#   docker cp <container_id>:/mk/mk-2024.0-full.tar.gz .


FROM rockylinux:9

MAINTAINER carlo.defalco@polimi.it


# Define variables.
ENV HOME /root
ENV mkPrefix /opt/mox/mk

ENV mkRoot /mk
ENV mkOutputBasename "${mkRoot}/mk-kami"

ENV mkKeepBuildDir yes
ENV mkFlags "--jobs=2 -v"

ENV mkBashrc "${HOME}/.bashrc_mk"
ENV mkBashrcSource "source ${mkBashrc}"

# Install dependencies.
RUN dnf upgrade -y && \    
    dnf --enablerepo crb install -y \
    gcc gcc-c++ gcc-gfortran make python3 texinfo \
    gawk procps wget openssh-clients p11-kit diffutils \
    git rsync zip unzip bzip2 glibc-static patch xz perl-locale \
    perl-Unicode-Normalize


# Clone repo.
RUN git clone https://github.com/carlodefalco/mk.git ${mkRoot} 
WORKDIR ${mkRoot}
RUN git checkout kami

# 1. Bootstrap.
WORKDIR ${mkRoot}
RUN bootstrap/bootstrap ${mkPrefix}


# 2. Toolchain.
WORKDIR ${mkRoot}/toolchains/gcc-glibc
RUN make install mkFlags="${mkFlags}"
RUN tar czvf ${mkOutputBasename}-toolchain.tar.gz ${mkPrefix}

# Enable toolchain by default.
# NB: the usual "${HOME}/.bashrc" would not get sourced
# when running non-interactively.

SHELL ["/bin/bash", "-c"]

RUN printf "\n# mk.\n\
source /u/sw/etc/profile\n\
module load gcc-glibc\n" >> ${mkBashrc}


## # 3. Base.
## WORKDIR ${mkRoot}/base
## RUN ${mkBashrcSource} && make install mkFlags="${mkFlags}"
## RUN tar czvf ${mkOutputBasename}-base.tar.gz ${mkPrefix}


## # 4. Packages.
## WORKDIR ${mkRoot}/pkgs
## RUN ${mkBashrcSource} && make libs mkFlags="${mkFlags}"

## # RUN ${mkBashrcSource} && make lifex mkFlags="${mkFlags}"
## # RUN tar czvf ${mkOutputBasename}-lifex.tar.gz ${mkPrefix}

## RUN ${mkBashrcSource} && make extra mkFlags="${mkFlags}"
## RUN tar czvf ${mkOutputBasename}-full.tar.gz ${mkPrefix}

## # Set configuration variables.
USER root
WORKDIR ${HOME}
