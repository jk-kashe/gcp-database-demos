FROM container-registry.oracle.com/database/ords-developer:24.4.0

WORKDIR /opt/oracle
COPY --chmod=755 start.sh .

ENTRYPOINT ["./start.sh"]
