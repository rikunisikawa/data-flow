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

# Create non-root user and working directory
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

# Ensure user-local bin is in PATH (pip --user installs here)
ENV PATH="/home/app/.local/bin:${PATH}"

# Install dbt / Athena adapter / Elementary as non-root (writes to /home/app/.local)
RUN pip install --user \
      "dbt-core==1.8.*" \
      "dbt-athena-community==1.8.*" \
      "elementary-data>=0.15,<0.16"

# Expose port for `dbt docs serve`
EXPOSE 8080
