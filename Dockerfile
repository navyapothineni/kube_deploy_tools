FROM        ruby:alpine

COPY        bin/sweeper /opt/bin/sweeper

COPY        config/sweeper.yaml /var/lib/sweeper/sweeper.yaml

ENTRYPOINT  ["/opt/bin/sweeper", "/var/lib/sweeper/sweeper.yaml"]