FROM public.ecr.aws/lambda/python:3.11

# Install build tools required for numpy and other C-extension packages
# Added gcc-c++ for the C++ compiler needed by numpy
RUN yum install -y gcc gcc-c++ make python3-devel

WORKDIR /build
COPY requirements.txt .
# Use the pip provided by the base image to install dependencies
RUN pip install -r requirements.txt -t /var/task/dependencies

CMD ["/bin/bash"]
