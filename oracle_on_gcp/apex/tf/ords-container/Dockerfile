FROM container-registry.oracle.com/database/ords-developer:24.4.0

WORKDIR /opt/oracle
COPY start.sh .
RUN chmod +x start.sh

ENTRYPOINT ["./start.sh"]
