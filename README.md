# Docker-Diablo2

Just a really dirty dump with all kinds of missing files. It's usable with XQuartz. HLS streaming needs some work still.

Get the install files off battle.net. The Dockerfile expects `D2-1.14b-Installer-enUS` and `D2LOD-1.14b-Installer-enUS` to be in this directory.

## setup

```sh
brew install xquartz
open -a xquartz
xhost + 127.0.0.1
```

## build

```sh
DOCKER_BUILDKIT=1 docker build --pull --build-arg REG_NAME=<your name> --build-arg D2_KEY=<your key> --build-arg D2LOD_KEY=<your key> -t docker-d2 --iidfile diid .
```

## run

```sh
docker run -it --rm docker-d2
su - wineuser
wine 'C:\Program Files\Diablo II\Game.exe' -w -nosound
```
