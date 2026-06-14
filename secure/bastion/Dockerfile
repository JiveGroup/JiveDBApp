# Bastion SSH tối giản cho test SSH Tunnel (KHÔNG dùng cho production).
# Cho phép đăng nhập bằng MẬT KHẨU (jdb/jdbtest) hoặc PRIVATE KEY, và bật
# AllowTcpForwarding để ứng dụng mở đường ống tới internal-postgres.
FROM alpine:3.20

RUN apk add --no-cache openssh-server openssh-client \
 && ssh-keygen -A \
 && mkdir -p /run/sshd /var/empty /etc/ssh/authorized_keys \
 && adduser -D -s /bin/sh jdb \
 && echo 'jdb:jdbtest' | chpasswd

COPY sshd_config /etc/ssh/sshd_config

EXPOSE 2222
CMD ["/usr/sbin/sshd", "-D", "-e"]
