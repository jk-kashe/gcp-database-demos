FROM python:3.13

WORKDIR /app
ENV PORT=8000
ENV WORKERS=4

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt 

COPY . .

CMD ["/bin/sh", "-c", "fastapi run main.py --port $PORT --workers $WORKERS"]