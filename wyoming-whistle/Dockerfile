# https://developers.home-assistant.io/docs/apps/configuration#app-dockerfile
ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG TARGETARCH
WORKDIR /usr/src

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        netcat-traditional \
        curl \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /usr/src/.venv \
    && /usr/src/.venv/bin/pip install --no-cache-dir -U pip wheel \
    && /usr/src/.venv/bin/pip install --no-cache-dir \
        "wyoming[zeroconf]==1.10.2" \
        "cactus-needle==3.2.8" \
        soxr \
        numpy

# Pre-download Whistle model weights (16.9 MB) and architecture-specific libneedle engine
RUN mkdir -p /usr/share/whistle \
    && curl -sSLf -o /usr/share/whistle/whistle.cact \
        https://huggingface.co/Cactus-Compute/whistle/resolve/main/whistle.cact \
    && arch="${TARGETARCH:-$(uname -m)}" \
    && case "${arch}" in \
        x86_64|amd64) needle_tag="manylinux2014_x86_64" ;; \
        aarch64|arm64) needle_tag="manylinux2014_aarch64" ;; \
        *) echo "Unsupported architecture: ${arch}" && exit 1 ;; \
    esac \
    && /usr/src/.venv/bin/python3 -c "import needle.agent.fetch as f; f.fetch_library(version='3.3.3', dest_dir='/usr/share/whistle', tag='${needle_tag}', generation=3)"

ENV PATH="/usr/src/.venv/bin:$PATH"
ENV NEEDLE_WHISTLE_WEIGHTS="/usr/share/whistle/whistle.cact"
ENV NEEDLE3_LIB_PATH="/usr/share/whistle/libneedle.so"

COPY rootfs /

# Set executable permissions on run scripts
RUN chmod +x \
    /etc/s6-overlay/s6-rc.d/wyoming-whistle/run \
    /etc/s6-overlay/s6-rc.d/wyoming-whistle/finish \
    /etc/s6-overlay/s6-rc.d/discovery/run

LABEL \
    io.hass.name="Wyoming Whistle" \
    io.hass.description="Ultra-lightweight local Speech-to-Text using Cactus Compute's Whistle model via Wyoming protocol" \
    io.hass.type="app" \
    io.hass.version="1.0.0"

HEALTHCHECK --start-period=30s --interval=30s --timeout=5s --retries=3 \
    CMD echo '{"type": "describe"}' | nc -w 1 localhost 10300 | grep -q "whistle" || exit 1
