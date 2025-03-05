FROM alpine

RUN apk add --update --no-cache eudev dnsmasq grep kmod && \
  echo 'libcomposite' >> /etc/modules

COPY entry.sh .

CMD ["/entry.sh"]
