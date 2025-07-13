.PHONY: build-KaggleApiLayer

build-KaggleApiLayer:
	@echo "Building layer with custom Dockerfile for x86_64 architecture..."
	docker build --platform linux/amd64 -t kaggle-layer-builder .
	mkdir -p "$(ARTIFACTS_DIR)/python"
	docker create --name temp-builder kaggle-layer-builder
	docker cp "temp-builder:/var/task/dependencies/." "$(ARTIFACTS_DIR)/python"
	docker rm -v "temp-builder"
