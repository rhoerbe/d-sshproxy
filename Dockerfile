FROM centos:centos7
LABEL maintainer="Rainer Hörbe <r2h2@hoerbe.at>" \
      version="0.1.0" \
      capabilities='--cap-drop=all --cap-add=sys_chroot --cap-add=setgid --cap-add=setuid --cap-add=audit_write --cap-add=kill --cap-add=chown --cap-add=dac_override'# capabilities='--cap-drop=all --cap-add=sys_chroot --cap-add=setgid --cap-add=setuid --cap-add=audit_write --cap-add=audit_control --cap-add=kill'


RUN yum -y update \
 && yum -y install curl net-tools telnet \
 && yum -y install openssh-server \
 && yum clean all
COPY install/opt/bin/* /opt/bin/
RUN chmod +x /opt/bin/*

# create container user owning git repo + web service processes
ARG CONTAINERUSER=sshproxy
ARG CONTAINERUID=343049
RUN adduser -u $CONTAINERUID $CONTAINERUSER
VOLUME /home/sshproxy

# Prepare ssh service (postpone key generation to run time!)
RUN rm -f /etc/ssh/ssh_host_*_key \
 && mkdir -p /opt/etc/ssh \
 && cp -p /etc/ssh/sshd_config /opt/etc/ssh/sshd_config \
 && echo 'GSSAPIAuthentication no' >> /opt/etc/ssh/sshd_config \
 && echo 'useDNS no' >> /opt/etc/ssh/sshd_config \
 && sed -i -e 's/#Port 22/Port 2022/' /opt/etc/ssh/sshd_config \
 && sed -i -e 's/^HostKey \/etc\/ssh\/ssh_host_/HostKey \/opt\/etc\/ssh\/ssh_host_/' /opt/etc/ssh/sshd_config \
 && chown -R $CONTAINERUSER:$CONTAINERGROUP /opt/etc
VOLUME /opt/etc/ssh
EXPOSE 2022

# Need to run as root because of sshd
# starting processes will drop off root privileges
CMD /opt/bin/start.sh
COPY REPO_STATUS  /opt/etc/REPO_STATUS