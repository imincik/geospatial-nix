# Get python-app-base image:
#   nix build .#container
#   docker load < ./result

# Build image:
#   docker build -t python-app:latest 

FROM python-app-base

RUN mkdir -p /opt/python-app
WORKDIR /opt/python-app

COPY src ./src
COPY pyproject.toml poetry.* README.md ./

RUN poetry install --without=dev

RUN printf '#!/usr/bin/env bash \n\
set -euo pipefail \n\
source .venv/bin/activate \n\
flask --app src/python_app run --host 0.0.0.0 --port 8000 \n\
' > entrypoint.bash

ENTRYPOINT [ "bash", "/opt/python-app/entrypoint.bash" ]
EXPOSE 8000
