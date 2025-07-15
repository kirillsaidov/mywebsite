# My website
This repo contains code of my personal website. It is written in `D` programming language + `Vibe.d` framework.

## Run manually
If you plan to run manually, then install:
* [D programming language compiler](https://dlang.org/)
* DUB package manager (bundled with the D compiler)

Clone this repository and execute:
```sh
cd mywebsite/
dub run
```
Output
```sh
Listening for requests on http://[::1]:8080/
Listening for requests on http://127.0.0.1:8080/
```

## Run with Docker
```
# build && run in background
docker run -d --network=host -v $PWD:/app -v $HOME/.dub:/app/.dub -w /app kirillsaidov/dlang:dmd-latest dub run
```

### LICENSE
MIT.

