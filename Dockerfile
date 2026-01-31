# Use Microsoft Dev Containers Python base (includes vscode user, shell setup, etc.)
ARG VARIANT="3.12-bullseye"
FROM mcr.microsoft.com/devcontainers/python:${VARIANT}

ARG DEBIAN_FRONTEND=noninteractive

# Remove Yarn (Node package manager) apt repo if present (not needed for PySpark)
# This avoids GPG/NO_PUBKEY failures during apt-get update.
RUN rm -f /etc/apt/sources.list.d/yarn.list /etc/apt/sources.list.d/yarn*.list \
  && rm -f /usr/share/keyrings/yarn.gpg /etc/apt/trusted.gpg.d/yarn.gpg

# Java 17 + minimal tools required to download/extract Spark
RUN apt-get update \
  && apt-get -y install --no-install-recommends \
     openjdk-17-jdk \
     curl \
     ca-certificates \
     tar \
  && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64
ENV PATH="${JAVA_HOME}/bin:${PATH}"

# Install Apache Spark 4.1.1 (Hadoop 3 build)
ENV SPARK_VERSION=4.1.1
ENV HADOOP_PROFILE=hadoop3

RUN curl -fsSL "https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-${HADOOP_PROFILE}.tgz" \
  | tar -xz -C /opt/ \
  && ln -s "/opt/spark-${SPARK_VERSION}-bin-${HADOOP_PROFILE}" /opt/spark

ENV SPARK_HOME=/opt/spark
ENV PATH="${SPARK_HOME}/bin:${PATH}"

# Python requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip3 --disable-pip-version-check --no-cache-dir install -r /tmp/requirements.txt \
  && rm -f /tmp/requirements.txt
