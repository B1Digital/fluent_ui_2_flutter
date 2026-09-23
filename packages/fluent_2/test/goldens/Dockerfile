# The image the golden PNGs in goldens/ are recorded in. See README.md.
#
# Linux amd64, because that is what CI (ubuntu-latest, x86_64) compares
# against. The Linux flutter_tester rasterises glyphs with the FreeType it
# links statically and reads no system font, so a bare Ubuntu reproduces the
# runner pixel for pixel. Build it for amd64 even on an arm64 host: arm64
# rounds some paths and gradients one level apart.
#
# Pinned: the base by its linux/amd64 manifest digest, Flutter by tag and by
# the revision that tag must resolve to. Changing either is a regeneration.
FROM ubuntu:24.04@sha256:496754492fb28b4d3049432f2ca787449331e23fb14f0dd3fffea86bf5a93eb4

ENV DEBIAN_FRONTEND=noninteractive TZ=UTC
RUN apt-get update \
 && apt-get install -y --no-install-recommends git curl unzip xz-utils ca-certificates \
 && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 -b 3.47.1 https://github.com/flutter/flutter.git /opt/flutter \
 && test "$(git -C /opt/flutter rev-parse HEAD)" = 6655482ec06e547f90abf8ae7590466f4415978d
ENV PATH=/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:$PATH
RUN git config --global --add safe.directory '*' \
 && flutter config --no-analytics --no-cli-animations \
 && flutter precache --universal \
 && flutter --version
