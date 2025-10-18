ARG ORDS_VERSION
FROM container-registry.oracle.com/database/ords:${ORDS_VERSION}

WORKDIR /opt/oracle
COPY start.sh .
USER root
RUN mkdir -p /opt/oracle/variables && chown -R oracle /opt/oracle/variables
RUN chmod 755 start.sh
USER oracle

ENTRYPOINT ["./start.sh"]