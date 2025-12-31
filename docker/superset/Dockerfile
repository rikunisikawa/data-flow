FROM apache/superset:3.0.0

USER root

# Install Athena SQLAlchemy driver.
RUN pip install --no-cache-dir "PyAthena[SQLAlchemy]" 

USER superset
