FROM public.ecr.aws/lambda/python:3.11

# Install build tools required for numpy and other C-extension packages
# Added gcc-c++ for the C++ compiler needed by numpy
RUN yum install -y gcc gcc-c++ make python3-devel

WORKDIR /build
COPY requirements.txt .
# Ensure dependencies directory exists even when skipping installs
RUN mkdir -p /var/task/dependencies

# Use the pip provided by the base image to install dependencies
# NOTE: Disabled to speed up local builds; re-enable for actual layer builds
# RUN pip install -r requirements.txt -t /var/task/dependencies

CMD ["/bin/bash"]
