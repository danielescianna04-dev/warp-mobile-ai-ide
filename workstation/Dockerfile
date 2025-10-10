# Usa immagine base con tutti i linguaggi
FROM us-central1-docker.pkg.dev/drape-mobile-ide/drape-repo/drape-workstation-base:latest

# Copia solo exec server e entrypoint (layer leggero)
COPY --chown=user:user exec-server.js /home/user/exec-server.js
COPY --chown=user:user entrypoint.sh /home/user/entrypoint.sh
RUN chmod +x /home/user/entrypoint.sh

USER user
WORKDIR /home/user/workspace

ENTRYPOINT ["/home/user/entrypoint.sh"]

