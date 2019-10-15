#!/bin/bash
#
# inject_delve.bash
#   Usage: inject_delve.bash <docker image>:<docker tag>
#
# inject_delve.bash wraps a provided docker image, injecting
# delve into it. Assumes the base image is built on alpine.

SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`

docker build -t $@ $SCRIPTPATH/.empty -f-<<EOF
FROM alpine:3.8 as dlv
RUN apk add --no-cache git go libc-dev && \
  go get -u github.com/go-delve/delve/cmd/dlv && \
  mv /root/go/bin/dlv /usr/bin/dlv && \
  rm -rf /root/go && \
  apk del --no-cache git go

FROM $@
COPY --from=dlv /usr/bin/dlv /usr/bin/dlv
EOF

