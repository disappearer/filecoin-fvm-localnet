FROM ghcr.io/hammertoe/lotus-localnet-multiarch:latest as lotus-test

FROM ghcr.io/hammertoe/boost-localnet-multiarch:sha-f1539cc as boost

FROM ubuntu:20.04 as runner

ENV BOOST_PATH /var/lib/boost
VOLUME /var/lib/boost
EXPOSE 8080

RUN apt update && apt install -y \
      curl \
      hwloc \
      jq

## Fix missing lib libhwloc.so.5
RUN ls -1 /lib/*/libhwloc.so.* | head -n 1 | xargs -n1 -I {} ln -s {} /lib/libhwloc.so.5

WORKDIR /app

COPY --from=boost /go/src/boostd /usr/local/bin/
COPY --from=boost /go/src/boost /usr/local/bin/
COPY --from=boost /go/src/boostx /usr/local/bin/
COPY --from=boost /go/src/booster-http /usr/local/bin/
COPY --from=boost /go/src/booster-bitswap /usr/local/bin/
COPY --from=lotus-test /usr/local/bin/lotus /usr/local/bin/
COPY --from=lotus-test /usr/local/bin/lotus-miner /usr/local/bin/
COPY --from=lotus-test /usr/local/bin/lotus-seed /usr/local/bin/

COPY boost/docker/devnet/boost/entrypoint.sh /app/entrypoint-boost.sh
COPY boost/docker/devnet/booster-http/entrypoint.sh /app/entrypoint-booster-http.sh
COPY boost/docker/devnet/booster-bitswap/entrypoint.sh /app/entrypoint-booster-bitswap.sh
COPY boost/docker/devnet/lotus/entrypoint.sh /app/entrypoint-lotus.sh
COPY boost/docker/devnet/lotus-miner/entrypoint.sh /app/entrypoint-lotus-miner.sh

## Test everything starts
RUN lotus -v && lotus-miner -v && lotus-seed -v && \
      boost -v && booster-http -v && booster-bitswap version
      
ENTRYPOINT ["/bin/bash"]
