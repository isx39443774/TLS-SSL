#!/bin/bash
# install ldapserver

cp /opt/docker/ldap.conf /etc/openldap/.
mkdir /etc/openldap/certs
cp /opt/docker/certif_CA.pem /etc/openldap/certs/.
cp /opt/docker/crt_server.pem /etc/openldap/certs/.
cp /opt/docker/key_server.pem /etc/openldap/certs/.

rm -rf /etc/openldap/slapd.d/*
rm -rf /var/lib/ldap/* 
cp /opt/docker/DB_CONFIG /var/lib/ldap/
slaptest -f /opt/docker/slapd.conf -F /etc/openldap/slapd.d/  
slapadd -F /etc/openldap/slapd.d -l /opt/docker/edt.org.ldif
chown -R ldap:ldap /etc/openldap/slapd.d/
chown -R ldap:ldap /var/lib/ldap/   
