# 🐍 PySpark Learn

A containerized development environment for learning **Python** and **PySpark**. This repository provides a ready-to-use setup with Jupyter notebooks, Apache Spark 4.1.1, and a comprehensive Python data stack.

---

## 📚 What's Inside

This repo is designed as a **personal learning sandbox** for:

- **Python Core Concepts** — Data structures (lists, dicts, tuples, strings), built-in functions, and more
- **PySpark** — Distributed data processing with Apache Spark's Python API
- **Jupyter Notebooks** — Interactive coding environment for experimentation

### Repository Structure

```
pyspark-learn/
├── src/
│   ├── pyspark/              # PySpark learning modules
│   │   ├── __init__.py
│   │   └── spark_session.py  # Spark session utilities
│   ├── python_core/          # Core Python concepts
│   │   ├── data_structures/  # Lists, dicts, tuples, strings
│   │   └── strings_built_in.py
│   └── scratch.ipynb         # Scratch notebook for experiments
├── Dockerfile                # Container image definition
├── docker-compose.yml        # Container orchestration
└── requirements.txt          # Python dependencies
```

---

## 🐳 Docker Container Setup

This project uses Docker to provide a consistent, reproducible development environment with all dependencies pre-installed.

### Dockerfile

The Dockerfile builds a development container based on **Microsoft Dev Containers Python 3.12** with:

| Component | Version | Description |
|-----------|---------|-------------|
| Python | 3.12 | Base language runtime |
| Java | OpenJDK 17 | Required for Spark execution |
| Apache Spark | 4.1.1 | Distributed processing engine |
| Hadoop | 3.x profile | Storage layer compatibility |

**Key Features:**
- Based on `mcr.microsoft.com/devcontainers/python:3.12-bullseye`
- Pre-configured `JAVA_HOME` and `SPARK_HOME` environment variables
- All Python dependencies from `requirements.txt` installed

### docker-compose.yml

The Compose file defines a `spark` service with the following configuration:

```yaml
Container Name: pyspark_dev
```

| Setting | Value | Purpose |
|---------|-------|---------|
| **Memory Limit** | 4GB | Hard cap on container memory |
| **CPU Limit** | 2.0 cores | Prevents runaway resource usage |
| **Spark Driver Memory** | 2GB | JVM heap for Spark driver |
| **Spark Executor Memory** | 2GB | JVM heap for Spark executors |

**Exposed Ports:**

| Port | Service |
|------|---------|
| `4040` | Spark Web UI (job monitoring) |
| `8888` | JupyterLab |
| `18080` | Spark History Server |

**Volume Mount:**
- Your project directory is mounted to `/workspace` inside the container

---

## 🚀 Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed
- [Docker Compose](https://docs.docker.com/compose/install/) installed
- (Optional) [VS Code](https://code.visualstudio.com/) with [Dev Containers extension](https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers)

### Quick Start

1. **Clone the repository**
   ```bash
   git clone <your-repo-url>
   cd pyspark-learn
   ```

2. **Create a `.env` file** (required by docker-compose)
   ```bash
   touch .env
   ```

3. **Build and start the container**
   ```bash
   docker-compose up -d --build
   ```

4. **Access the development environment**
   - **JupyterLab**: Open http://localhost:8888
   - **Spark UI**: Open http://localhost:4040 (when a Spark job is running)

5. **Attach to the container** (for terminal access)
   ```bash
   docker exec -it pyspark_dev bash
   ```

### Stopping the Environment

```bash
docker-compose down
```

---

## 🔧 VS Code Dev Container (Optional)

To use this with VS Code Dev Containers, create a `.devcontainer/devcontainer.json` file:

```json
{
  "name": "PySpark Learn",
  "dockerComposeFile": "../docker-compose.yml",
  "service": "spark",
  "workspaceFolder": "/workspace",
  "customizations": {
    "vscode": {
      "extensions": [
        "ms-python.python",
        "ms-toolsai.jupyter",
        "ms-python.vscode-pylance"
      ],
      "settings": {
        "python.defaultInterpreterPath": "/usr/local/bin/python"
      }
    }
  },
  "remoteUser": "vscode"
}
```

Then use **Command Palette** → **Dev Containers: Reopen in Container**.

---

## 📦 Installed Python Packages

The environment comes with a rich set of pre-installed packages:

| Category | Packages |
|----------|----------|
| **Spark/Jupyter** | pyspark, jupyterlab, ipykernel |
| **Data Stack** | numpy, pandas, pyarrow |
| **Cloud** | boto3, snowflake-snowpark-python |
| **Testing** | pytest, pytest-xdist, parameterized |
| **Utilities** | python-dotenv, requests, PyYAML |

See `requirements.txt` for the complete list with versions.

---

## 💡 Tips for Learning

1. **Start with notebooks** — Use `src/scratch.ipynb` for quick experiments
2. **Explore Python basics** — Check `src/python_core/` for data structure examples
3. **Build PySpark skills** — Add your learning notebooks to `src/pyspark/`
4. **Monitor Spark jobs** — Always keep http://localhost:4040 open when running Spark code

---

## 📄 License

This is a personal learning repository. Feel free to fork and adapt for your own learning journey!
