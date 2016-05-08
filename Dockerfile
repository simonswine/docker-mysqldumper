FROM alpine:3.1
RUN apk add --update mysql-client bash && rm -rf /var/cache/apk/*

COPY backup.sh /usr/local/backup/backup.sh
WORKDIR /usr/local/backup

CMD ["/bin/bash", "/usr/local/backup/backup.sh"]
