FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    gcc \
    make \
    libcap-dev \
    iproute2 \
    kmod \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY dirtyfrag.c .
COPY entrypoint.sh .

RUN gcc -O2 -o dirtyfrag dirtyfrag.c -lpthread

RUN chmod +x entrypoint.sh

RUN useradd -ms /bin/bash -u 10001 choreouser

USER 10001

CMD ["./entrypoint.sh"]
