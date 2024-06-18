# Install conda dependencies
FROM mambaorg/micromamba:1.5.8
COPY --chown=$MAMBA_USER:$MAMBA_USER env.yaml /tmp/env.yaml
RUN micromamba install -y -n base -f /tmp/env.yaml && micromamba clean --all --yes
ARG MAMBA_DOCKERFILE_ACTIVATE=1 

# Set up transition repo
ADD . .
RUN R -e 'options(renv.config.pak.enabled = TRUE); renv::restore()'

# This disables the interactive parts of the script
ENV CI=1 GITHUB_PAT=
# The .module-ignore seems to prevent certain lessons from being converted, so we truncate it
RUN > .module-ignore
