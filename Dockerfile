FROM mirantis/ucp-interlock-proxy:3.7.10

COPY entrypoint.sh watch.sh /
RUN chmod 755 /entrypoint.sh /watch.sh
CMD ["/entrypoint.sh"]
