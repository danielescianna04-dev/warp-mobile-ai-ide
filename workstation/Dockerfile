# Usa immagine base con tutti i linguaggi
FROM us-central1-docker.pkg.dev/drape-mobile-ide/drape-repo/drape-workstation-base:latest

# Torna root per copiare file
USER root

# Assicurati che la directory esista
RUN mkdir -p /home/user && chown user:user /home/user

# Copia exec server e entrypoint
COPY exec-server.js /home/user/exec-server.js
COPY entrypoint.sh /home/user/entrypoint.sh

# Cambia ownership e permessi
RUN chown user:user /home/user/exec-server.js /home/user/entrypoint.sh \
    && chmod +x /home/user/entrypoint.sh

# Verifica che i file esistano
RUN ls -la /home/user/

USER user
WORKDIR /home/user/workspace

ENTRYPOINT ["/home/user/entrypoint.sh"]

