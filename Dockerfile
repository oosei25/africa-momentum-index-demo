
FROM python:3.11-slim

# System deps for building wheels
RUN apt-get update && apt-get install -y --no-install-recommends make curl \
 && rm -rf /var/lib/apt/lists/*

# psycopg2 # build-essential gcc libpq-dev

# Python env quality-of-life
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# Workdir
WORKDIR /app

# Install Python deps first (cached layer)
COPY requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt

# App code
COPY . /app

# Expose Streamlit port
EXPOSE 8501

# Default command
CMD ["streamlit", "run", "dashboard/app.py", "--server.port=8501", "--server.address=0.0.0.0"]
