# LDAPSERVER19:TLS

## Generar certificats
### Generem claus privades del servidor

```
[root@localhost ldapserver19:tls]# openssl genrsa -out server_key.pem
Generating RSA private key, 2048 bit long modulus (2 primes)
............................................................................................................................................+++++
................+++++
e is 65537 (0x010001)
```
```
[root@localhost ldapserver19:tls]# openssl genrsa -out ca_key.pem
Generating RSA private key, 2048 bit long modulus (2 primes)
.....................................................+++++
......................................................................................................+++++
e is 65537 (0x010001)
```
### Creació CA

```
[root@localhost ldapserver19:tls]$ cat ca.conf
basicConstraints = critical,CA:FALSE
extendedKeyUsage = serverAuth,emailProtection
```

### Generem un certificat propi de l'entitat CA.
```
[root@localhost ldapserver19:tls]# openssl req -new -x509 -nodes -sha1 -days 365 -key ca_key.pem -out ca_certif.pem
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:ca
State or Province Name (full name) []:Barcelona
Locality Name (eg, city) [Default City]:Barcelona
Organization Name (eg, company) [Default Company Ltd]:Veritat Absoluta
Organizational Unit Name (eg, section) []:Certificats
Common Name (eg, your name or your server's hostname) []:Veritat Absoluta
Email Address []:admin@edt.org
```

### Generem un certificat request per a la CA

```
[root@localhost ldapserver19:tls]# openssl req -new -key server_key.pem -out server_certif.pem
You are about to be asked to enter information that will be incorporated
into your certificate request.
What you are about to enter is what is called a Distinguished Name or a DN.
There are quite a few fields but you can leave some blank
For some fields there will be a default value,
If you enter '.', the field will be left blank.
-----
Country Name (2 letter code) [XX]:ca
State or Province Name (full name) []:Barcelona
Locality Name (eg, city) [Default City]:Barcelona
Organization Name (eg, company) [Default Company Ltd]:M11
Organizational Unit Name (eg, section) []:Dep. Informatica
Common Name (eg, your name or your server's hostname) []:ldap.edt.org
Email Address []:admin@edt.org

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:jupiter
An optional company name []:edt
```

### CA firma el certificat

```
[root@localhost ldapserver19:tls]# openssl x509 -CA ca_certif.pem -CAkey ca_key.pem -req -in server_certif.pem -days 365 -sha1 -extfile ca.conf -CAcreateserial -out crt_server.pem
Signature ok
subject=C = ca, ST = Barcelona, L = Barcelona, O = M11, OU = Dep. Informatica, CN = ldap.edt.org, emailAddress = admin@edt.org
Getting CA Private Key

```

## Configuració per TLS

### Configuració del server

#### Fitxer slapd.conf
```
TLSCACertificateFile    /etc/openldap/certs/ca_certif.pem
TLSCertificateFile      /etc/openldap/certs/server_certif.pem
TLSCertificateKeyFile   /etc/openldap/certs/server_key.pem
TLSVerifyClient         never
TLSCipherSuite          HIGH:MEDIUM:LOW:+SSLv2
```

#### Fitxer ldap.conf
```
TLS_CACERT /etc/openldap/certs/ca_certif.pem
SASL_NOCANON    on
URI ldap://ldap.edt.org
BASE dc=edt,dc=org
```

#### Fitxer startup.sh
```
/sbin/slapd -d0 -h "ldap:/// ldaps:/// ldapi:///"
```

### Configuració del client
* Afegir entrada corresponent a /etc/hosts

* Copiar el certificat de la CA creat previament a /etc/openldap/ca_certif.pem

* Editar el fitxer /etc/open/ldap/ldap.conf:
```
TLS_CACERT /etc/openldap/ca_certif.pem
TLS_REQCERT allow

URI ldap://ldap.edt.org
BASE dc=edt,dc=org

SASL_NOCANON on
```

## Comprovació

* Arrencar el servidor ldap
```
docker run --rm --name ldap.edt.org -h ldap.edt.org  -p 389:389 -p 636:636 -d isx39443774/ldapserver19:tls
```

* ldapsearch
```
[root@localhost ldapserver19:tls]# ldapsearch -x -LLL -ZZ dn
dn: dc=edt,dc=org

dn: ou=maquines,dc=edt,dc=org

dn: ou=clients,dc=edt,dc=org

dn: ou=productes,dc=edt,dc=org

...
```

```
[root@localhost ldapserver19:tls]# ldapsearch -x -LLL -H ldaps://ldap.edt.org dn
dn: dc=edt,dc=org

dn: ou=maquines,dc=edt,dc=org

dn: ou=clients,dc=edt,dc=org

dn: ou=productes,dc=edt,dc=org

...
```

* openssl
```
[root@localhost ldapserver19:tls]# openssl s_client -connect ldap.edt.org:636
CONNECTED(00000003)
depth=1 C = ca, ST = Barcelona, L = Barcelona, O = Veritat Absoluta, OU = Certificats, CN = Veritat Absoluta, emailAddress = admin@edt.org
verify error:num=19:self signed certificate in certificate chain
verify return:1
depth=1 C = ca, ST = Barcelona, L = Barcelona, O = Veritat Absoluta, OU = Certificats, CN = Veritat Absoluta, emailAddress = admin@edt.org
verify return:1
depth=0 C = ca, ST = Barcelona, L = Barcelona, O = EDT, OU = Dep.  Informatica, CN = ldap.edt.org, emailAddress = admin@edt.org
verify return:1
---
```
