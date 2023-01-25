# Get geonix-base-image by running using following commands in development
# shell:
# geonix build geonix-base-image
# docker load < ./result
FROM geonix-base

RUN mkdir -p /opt/deployment
WORKDIR /opt/deployment

# Install all Nix dependencies upfront.
# Install Nix deployment package and run deployment shell to trigger download of
# all its dependencies as well.
COPY flake.nix flake.lock deployment.nix ./
RUN nix profile install --accept-flake-config .#deployment
RUN nix develop --accept-flake-config .#deployment --command echo OK

# Install Poetry managed dependencies and the application
COPY src ./src
COPY pyproject.toml poetry.* README.md ./

RUN nix develop --accept-flake-config .#deployment --command poetry install --without=dev

# Cleanup
RUN nix store gc

ENTRYPOINT [ "entrypoint" ]
EXPOSE 8000
