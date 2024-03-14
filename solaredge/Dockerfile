ARG BUILD_FROM
FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

ENV LANG C.UTF-8

# Install requirements for add-on
RUN apk add --no-cache \
	tcpdump \
    iptables \
    nftables \
	coreutils \
	build-base

#--------------------------------------------------------------------------
#Install Python 3
#This hack is widely applied to avoid python printing issues in docker containers.
#See: https://github.com/Docker-Hub-frolvlad/docker-alpine-python3/pull/13
ENV PYTHONUNBUFFERED=1
RUN echo "**** install Python ****" && \
    apk add --no-cache python3 python3-dev pipx && \
    if [ ! -e /usr/bin/python ]; then ln -sf python3 /usr/bin/python ; fi
#--------------------------------------------------------------------------

RUN apk add --no-cache \
	py3-psycopg2 \
    py3-pycryptodome

# Copy data for add-on
COPY se-logger/opt/* /opt/se-logger

# --------------------------------------
# Finish image
# --------------------------------------

# Make sure that S6 is not so hard on our service startup/shutdown
ENV \
    S6_SERVICES_GRACETIME=18000

# Copy data
COPY rootfs /

WORKDIR /
