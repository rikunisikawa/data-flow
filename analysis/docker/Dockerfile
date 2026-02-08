FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /workspace

COPY analysis/requirements.txt /workspace/analysis/requirements.txt
COPY analysis/docker/requirements.txt /workspace/analysis/docker/requirements.txt

RUN pip install --no-cache-dir -r /workspace/analysis/requirements.txt \
    && pip install --no-cache-dir -r /workspace/analysis/docker/requirements.txt

CMD ["bash"]
