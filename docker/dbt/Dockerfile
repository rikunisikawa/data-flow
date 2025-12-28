# Minimal dbt CLI image for Athena adapter
FROM python:3.11-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    DBT_PROFILES_DIR=/work/.dbt

# Install basic OS dependencies (curl for health checks/debug)
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       ca-certificates curl bash \
    && rm -rf /var/lib/apt/lists/*

# Install dbt and the Athena adapter as root so the CLI is in /usr/local/bin
# Pin to 1.8 minor series for compatibility with existing project artifacts
RUN pip install \
      "dbt-core==1.8.*" \
      "dbt-athena-community==1.8.*"

# Create non-root user and working directory after installing tools
RUN useradd -m -u 1000 -s /bin/bash app \
    && mkdir -p /work \
    && chown app:app /work

USER app
WORKDIR /work

# Copy dbt project and profiles for non-interactive execution environments (e.g., Fargate)
COPY --chown=app:app data_flow_dbt /work/data_flow_dbt
COPY --chown=app:app dbt_profiles/ /work/dbt_profiles/
COPY --chown=app:app dbt_profiles/ /work/.dbt/

# Maintain compatibility with existing tooling expecting /work/data_flow_dbt
ENV DBT_PROFILES_DIR=/work/dbt_profiles

# Ensure user-local bin is in PATH (in case additional tools are installed later)
ENV PATH="/home/app/.local/bin:${PATH}"

# Expose port for `dbt docs serve`
EXPOSE 8080
