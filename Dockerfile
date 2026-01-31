# Python 3.14 on Debian bullseye via Microsoft devcontainer image
ARG VARIANT="3.12-bullseye"
FROM mcr.microsoft.com/vscode/devcontainers/python:${VARIANT}

ARG DEBIAN_FRONTEND=noninteractive

# 1) Java (required by Spark)
RUN apt-get update \
  && apt-get -y install --no-install-recommends \
      openjdk-17-jdk \
      curl \
      ca-certificates \
      tar \
  && rm -rf /var/lib/apt/lists/*

# Use a more flexible way to set JAVA_HOME in case the path varies slightly
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# 2) Spark 4.1.1 install
ENV SPARK_VERSION=4.1.1
ENV HADOOP_PROFILE=hadoop3
RUN curl -fsSL "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-${HADOOP_PROFILE}.tgz" \
  | tar -xz -C /opt/ \
  && ln -s "/opt/spark-${SPARK_VERSION}-bin-${HADOOP_PROFILE}" /opt/spark

ENV SPARK_HOME=/opt/spark
# Add Spark to PATH and PYTHONPATH
ENV PATH="${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${PATH}"
ENV PYTHONPATH="${SPARK_HOME}/python:${SPARK_HOME}/python/lib/py4j-0.10.9.7-src.zip:${PYTHONPATH}"

# 3) Python deps
COPY requirements.txt /tmp/requirements.txt
RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/requirements.txt \
  && rm -f /tmp/requirements.txt