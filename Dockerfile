######## Build UI ########
FROM node:lts as build-ui

ARG CLASH_DASHBOARD_VERSION=83d1bcc8488e4cd34b42828259a059fd429def47
ENV CLASH_DASHBOARD_VERSION=${CLASH_DASHBOARD_VERSION}


WORKDIR /tmp
RUN wget https://github.com/Dreamacro/clash-dashboard/archive/$CLASH_DASHBOARD_VERSION.zip -O clash-dashboard-$CLASH_DASHBOARD_VERSION.zip
RUN unzip clash-dashboard-$CLASH_DASHBOARD_VERSION.zip

WORKDIR /tmp/clash-dashboard-$CLASH_DASHBOARD_VERSION
RUN npm install
RUN npm run build
RUN mv /tmp/clash-dashboard-$CLASH_DASHBOARD_VERSION/dist /ui


######## Build Application ########

FROM golang:alpine as build-app

ARG CLASH_VERSION=dd61e8d19dad69a7fa1e838f718c79eed3483e0d
ENV CLASH_VERSION=${CLASH_VERSION}

RUN apk add --no-cache make git && \
    wget http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country.tar.gz -O /tmp/GeoLite2-Country.tar.gz && \
    tar zxvf /tmp/GeoLite2-Country.tar.gz -C /tmp && \
    mv /tmp/GeoLite2-Country_*/GeoLite2-Country.mmdb /Country.mmdb

WORKDIR /tmp
RUN wget https://github.com/Dreamacro/clash/archive/$CLASH_VERSION.zip -O clash-$CLASH_VERSION.zip
RUN unzip clash-$CLASH_VERSION.zip

WORKDIR /tmp/clash-$CLASH_VERSION
RUN go mod download && \
    make linux-amd64 && \
    mv ./bin/clash-linux-amd64 /clash



######## Finally ########

FROM alpine:latest

RUN apk add --no-cache ca-certificates
COPY --from=build-ui /ui /ui
COPY --from=build-app /Country.mmdb /root/.config/clash/
COPY --from=build-app /clash /
ENTRYPOINT ["/clash"]

