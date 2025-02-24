FROM alpine:edge AS liblsquic-builder
WORKDIR /src

RUN apk add --no-cache build-base git apk-tools abuild cmake go perl linux-headers

RUN abuild-keygen -a -n && \
    cp /root/.abuild/-*.rsa.pub /etc/apk/keys/

COPY docker/APKBUILD-boringssl boringssl/APKBUILD
RUN cd boringssl && abuild -F -r && cd ..

RUN apk add --repository /root/packages/src boringssl boringssl-dev boringssl-static

RUN apk add --no-cache zlib-dev zlib-static libevent-dev libevent-static

COPY docker/APKBUILD-lsquic lsquic/APKBUILD
RUN cd lsquic && abuild -F -r && cd ..

RUN apk add --repository /root/packages/src lsquic-static

RUN mkdir tmp && cd tmp && \
    ar -x /usr/lib/libssl.a && \
    ar -x /usr/lib/libcrypto.a && \
    ar -x /usr/lib/liblsquic.a && \
    ar rc liblsquic.a *.o && \
    strip --strip-unneeded liblsquic.a && \
    ranlib liblsquic.a && \
    cp liblsquic.a /root/liblsquic.a && \
    cd .. && rm -rf tmp


FROM crystallang/crystal:1.1.1-alpine AS builder
RUN apk add --no-cache sqlite-static yaml-static

WORKDIR /invidious
COPY ./shard.yml ./shard.yml
COPY ./shard.lock ./shard.lock
RUN shards install

COPY --from=liblsquic-builder /root/liblsquic.a ./lib/lsquic/src/lsquic/ext/liblsquic.a

COPY ./src/ ./src/
# TODO: .git folder is required for building – this is destructive.
# See definition of CURRENT_BRANCH, CURRENT_COMMIT and CURRENT_VERSION.
COPY ./.git/ ./.git/

RUN crystal spec --warnings all \
    --link-flags "-lxml2 -llzma"

RUN crystal build ./src/invidious.cr \
    --static --warnings all \
    --link-flags "-lxml2 -llzma"

FROM alpine:latest
RUN apk add --no-cache librsvg ttf-opensans
WORKDIR /invidious
RUN addgroup -g 1000 -S invidious && \
    adduser -u 1000 -S invidious -G invidious
COPY ./assets/ ./assets/
COPY --chown=invidious ./config/config.* ./config/
RUN mv -n config/config.example.yml config/config.yml
RUN sed -i 's/host: \(127.0.0.1\|localhost\)/host: postgres/' config/config.yml
COPY ./config/sql/ ./config/sql/
COPY ./locales/ ./locales/
COPY --from=builder /invidious/invidious .
RUN chmod o+rX -R ./assets ./config ./locales

EXPOSE 3000
USER invidious
CMD [ "/invidious/invidious" ]
