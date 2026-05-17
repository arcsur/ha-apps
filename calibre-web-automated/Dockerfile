# https://developers.home-assistant.io/docs/apps/configuration#app-dockerfile
ARG BUILD_FROM=ghcr.io/crocodilestick/calibre-web-automated:v4.0.6
FROM ${BUILD_FROM}

# Execute during the build of the image
ARG TARGETARCH
ARG BASHIO_VERSION=v0.17.5

# Install dependencies for bashio (curl and jq)
RUN apt-get update && apt-get install -y curl jq && rm -rf /var/lib/apt/lists/*

# Install bashio
RUN curl -J -L -o /tmp/bashio.tar.gz "https://github.com/hassio-addons/bashio/archive/${BASHIO_VERSION}.tar.gz" \
    && mkdir /tmp/bashio \
    && tar zxvf /tmp/bashio.tar.gz --strip 1 -C /tmp/bashio \
    && mv /tmp/bashio/lib /usr/lib/bashio \
    && ln -s /usr/lib/bashio/bashio /usr/bin/bashio \
    && rm -rf /tmp/bashio.tar.gz /tmp/bashio

# Copy the ha-config s6-rc service
COPY ha-config/ /etc/s6-overlay/s6-rc.d/ha-config/

# Register the service in the user bundle and set permissions
RUN chmod +x /etc/s6-overlay/s6-rc.d/ha-config/run \
    && touch /etc/s6-overlay/s6-rc.d/user/contents.d/ha-config \
    && touch /etc/s6-overlay/s6-rc.d/cwa-init/dependencies.d/ha-config

# Set S6_BEHAVIOUR_IF_STAGE2_FAILS to 2 to ensure that if the stage 2 service fails,
# the container will exit with an error code instead of trying to continue running.
# ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV PUID=1000
ENV PGID=1000

LABEL \
    org.opencontainers.image.title="Calibre Web Automated" \
    org.opencontainers.image.description="Calibre-Web Automated aims to be an all-in-one solution, combining the modern lightweight web UI from Calibre-Web with the robust, versatile feature set of Calibre, with a slew of extra features and automations thrown in on top." \
    org.opencontainers.image.source="https://github.com/crocodilestick/calibre-web-automated" \
    org.opencontainers.image.licenses="GPL 3.0"
