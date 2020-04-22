# Docker-Diablo2 with HLS streaming

Just a really dirty dump with all kinds of missing files.

```sh
DOCKER_BUILDKIT=1 docker build --pull --build-arg REG_NAME=<your name> --build-arg D2_KEY=<your key> --build-arg D2LOD_KEY=<your key> -t docker-d2 --iidfile diid .
```
