# Gustavo Tello
# M11-SAD EDT 2019-2020
# ldapserver19:tls

FROM fedora:27  
LABEL version="1.0"
LABEL author="isx43577298"
RUN  dnf -y install openldap-servers openldap-clients openssl
RUN mkdir /opt/docker
COPY * /opt/docker/
RUN chmod +x /opt/docker/startup.sh
WORKDIR /opt/docker
CMD /opt/docker/startup.sh
                                                    
