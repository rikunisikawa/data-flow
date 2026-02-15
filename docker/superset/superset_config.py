import os

# Core settings
BABEL_DEFAULT_LOCALE = "ja"
BABEL_DEFAULT_TIMEZONE = "Asia/Tokyo"
TIMEZONE = "Asia/Tokyo"

# Use env override to keep config reproducible and secret-free.
SQLALCHEMY_DATABASE_URI = os.environ.get(
    "SUPERSET_DATABASE_URI",
    "postgresql+psycopg2://superset:superset@superset-db:5432/superset",
)
