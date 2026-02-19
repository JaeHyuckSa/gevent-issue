FROM python:3.14-rc-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY celery_app.py .

CMD ["celery", "-A", "celery_app", "worker", "-P", "gevent", "-c", "4", "-Q", "gevent", "--loglevel=warning"]
