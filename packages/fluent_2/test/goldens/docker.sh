#!/usr/bin/env bash
# Runs the golden tests in the image that owns them (Dockerfile, README.md).
#
#   docker.sh                   compare with the committed images
#   docker.sh --update-goldens  regenerate them
#
# The container works on a copy of the tree without any .dart_tool or build/:
# package_config.json holds absolute paths, so a Linux `pub get` in the host's
# tree would break the host's own tooling. Only images come back: goldens/*.png
# after a successful --update-goldens, and failures/ when a comparison fails.
set -euo pipefail

here=$(cd "$(dirname "$0")" && pwd)
root=$(cd "$here/../../../.." && pwd)
image=fluent-2-goldens:3.47.1

docker build --platform linux/amd64 -t "$image" - <"$here/Dockerfile"

docker run --rm --platform linux/amd64 \
  -v "$root:/src:ro" -v "$here:/out" \
  "$image" bash -c '
    set -euo pipefail
    mkdir /work
    tar -C /src --exclude=.dart_tool --exclude=build \
      --exclude="packages/*/test/goldens/failures" -cf - pubspec.yaml packages |
      tar -C /work -xf -
    cd /work
    flutter pub get
    cd packages/fluent_2
    status=0
    flutter test "$@" test/goldens/ || status=$?
    rm -rf /out/failures
    if [ -d test/goldens/failures ]; then cp -r test/goldens/failures /out/; fi
    if [ "$status" = 0 ] && [ "${1:-}" = --update-goldens ]; then
      cp test/goldens/goldens/*.png /out/goldens/
    fi
    # A rootful Docker on a Linux host would leave these owned by root.
    chown -R --reference=/out /out/goldens /out/failures 2>/dev/null || true
    exit "$status"
  ' bash "$@"
