#!/bin/bash

# Avvia exec server in background
node /home/user/exec-server.js &

# Mantieni il container attivo
tail -f /dev/null
