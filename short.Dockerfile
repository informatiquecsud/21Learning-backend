FROM donnerc/runestone-server:1920
LABEL authors="cedonner@gmail.com"

COPY docker/entrypoint-short.sh /usr/local/sbin/entrypoint.sh

CMD /bin/bash /usr/local/sbin/entrypoint.sh
