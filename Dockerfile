FROM alpine:3.8

COPY ./patches /mtproxy/patches

RUN apk add --no-cache --virtual .build-deps \
      git make gcc musl-dev linux-headers openssl-dev \
    && git clone --single-branch https://github.com/TelegramMessenger/MTProxy.git /mtproxy/sources \
    && cd /mtproxy/sources \
    && patch -p0 -i /mtproxy/patches/randr_compat.patch \
    && make -j$(getconf _NPROCESSORS_ONLN) \
    && cp /mtproxy/sources/objs/bin/mtproto-proxy /mtproxy/ \
    && rm -rf /mtproxy/{sources,patches} \
    && apk add --virtual .rundeps libcrypto1.0 \
    && apk del .build-deps

FROM alpine:3.8
LABEL maintainer="Alex Bogatikov <alexey.bogatikov@gmail.com>" \
      description="Telegram Messenger MTProto zero-configuration proxy server."

ENV HTTP_PORT=8080
ENV STATISTICS_PORT 2398

RUN apk add --no-cache curl \
  && ln -s /usr/lib/libcrypto.so.43 /usr/lib/libcrypto.so.1.0.0

WORKDIR /mtproxy

COPY --from=0 /mtproxy/sources/objs/bin/mtproto-proxy .
COPY ./bin/mtproxy.sh /bin/
RUN chmod 777 /bin/mtproxy.sh

VOLUME /data

ENTRYPOINT ["/bin/mtproxy.sh"]
CMD [ \
  "--slaves", "2", \
  "--max-special-connections", "60000", \
  "--allow-skip-dh" \
]
