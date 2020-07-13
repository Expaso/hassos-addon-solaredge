ARG BUILD_FROM
FROM $BUILD_FROM

ENV LANG C.UTF-8

# Install requirements for add-on
RUN apk add --no-cache python3 tcpdump coreutils build-base python3-dev
RUN pip3 install influxdb pycryptodome
# \ tshark xxd

# Set data as our working dir. 
WORKDIR /data

# Copy data for add-on
COPY se-logger/opt/* /opt/se-logger

# Copy runfile and give execute permissions
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]

