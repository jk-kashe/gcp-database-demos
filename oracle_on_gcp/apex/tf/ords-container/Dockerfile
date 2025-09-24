FROM container-registry.oracle.com/database/ords-developer:24.4.0

WORKDIR /opt/oracle
COPY start.sh .
USER root
RUN chmod 755 start.sh
USER oracle

ENTRYPOINT ["./start.sh"]
