FROM python:3.13

WORKDIR /app
ENV PORT 8080

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt 

COPY . .

CMD ["/bin/sh", "-c", "streamlit run home.py --server.enableCORS false --browser.serverAddress 0.0.0.0 --browser.gatherUsageStats false --server.port $PORT"]
