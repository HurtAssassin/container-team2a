FROM python:3.8-slim

WORKDIR /app

# Dependencias del sistema (psycopg2 suele requerir build tools si no hay wheel)
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
  && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/requirements.txt
RUN pip install --no-cache-dir "pip<24" "setuptools==44.1.1" "wheel<0.38"
RUN pip install --no-cache-dir -r /app/requirements.txt

# Copiar código (en este repo la app vive en /app)
COPY app /app/app
COPY entrypoint.sh /app/entrypoint.sh

EXPOSE 5000

# Usa entrypoint para mapear DB_* -> DBHOST/DBUSER/DBPASS/DBNAME
ENTRYPOINT ["/app/entrypoint.sh"]

# Ejecutar Flask con gunicorn (si en tu requirements no viene gunicorn,
# puedes ejecutar flask directamente; pero gunicorn es mejor práctica)
ENV FLASK_APP=app/app.py
CMD ["flask", "run", "--host=0.0.0.0", "--port=5000"]