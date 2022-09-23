FROM alpine

RUN apk add --update --no-cache eudev dnsmasq && \
  echo 'libcomposite' >> /etc/modules

COPY entry.sh .

CMD ["/entry.sh"]
