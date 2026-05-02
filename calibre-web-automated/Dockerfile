# https://developers.home-assistant.io/docs/apps/configuration#app-dockerfile
ARG BUILD_FROM=ghcr.io/crocodilestick/calibre-web-automated:v4.0.6
FROM ${BUILD_FROM}

# Execute during the build of the image
ARG TEMPIO_VERSION=2021.09.0
ARG TARGETARCH
RUN \
    if [ -z "${TARGETARCH}" ]; then \
    echo "TARGETARCH is not set, please use Docker BuildKit for the build." && exit 1; \
    fi \
    && case "${TARGETARCH}" in \
    amd64) tempio_arch="amd64" ;; \
    arm64) tempio_arch="aarch64" ;; \
    *) echo "Unsupported TARGETARCH: ${TARGETARCH}" && exit 1 ;; \
    esac \
    && curl -sSLf -o /usr/bin/tempio \
    "https://github.com/home-assistant/tempio/releases/download/${TEMPIO_VERSION}/tempio_${tempio_arch}"

# Copy root filesystem
#COPY rootfs /

LABEL \
    org.opencontainers.image.title="Calibre Web Automated" \
    org.opencontainers.image.description="Calibre-Web Automated aims to be an all-in-one solution, combining the modern lightweight web UI from Calibre-Web with the robust, versatile feature set of Calibre, with a slew of extra features and automations thrown in on top." \
    org.opencontainers.image.source="https://github.com/crocodilestick/calibre-web-automated" \
    org.opencontainers.image.licenses="GPL 3.0"
