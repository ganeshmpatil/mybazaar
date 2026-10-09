FROM python:3.10-slim

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev gcc && \
    rm -rf /var/lib/apt/lists/*

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

RUN mkdir -p /app/static/products

EXPOSE 8000

CMD ["sh", "-c", "python -m alembic upgrade head && uvicorn src.mybazaar.main:app --host 0.0.0.0 --port ${PORT:-8000}"]
