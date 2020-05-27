# Ldaperver19:tls

Ldap con conexiones seguras TLS/SSL  y startTLS.

## Generar cerificats
### Generem keys privades
```
[gustavo@localhost ldapserver19:tls]$ openssl genrsa -out key_server.pem 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
.......+++++
...+++++
e is 65537 (0x010001)

[gustavo@localhost ldapserver19:tls]$ openssl genrsa -out key_CA.pem 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
.......................+++++
.....................................+++++
e is 65537 (0x010001)
```

### Generem un certificat propi de l'entitat CA que dura 365 dies.
```
[gustavo@localhost ldapserver19:tls]$ openssl req -new -x509 -nodes -sha1 -days 365 -key key_CA.pem -out certif_CA.pem
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
Organizational Unit Name (eg, section) []:Certificats covid19
Common Name (eg, your name or your server's hostname) []:Veritat_Absoluta   
Email Address []:admin@edt.org
```

### Generem un certificat request per enviar a l'entitat CA
```
[gustavo@localhost ldapserver19:tls]$ openssl req -new -key key_server.pem -out certif_server.pem
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
Organization Name (eg, company) [Default Company Ltd]:M11-SAD
Organizational Unit Name (eg, section) []:Informatica
Common Name (eg, your name or your server's hostname) []:ldap.edt.org
Email Address []:admin@edt.org

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:request password
An optional company name []:edt
```

### Definim les extensions en el fitxer ca.conf.
```
[gustavo@localhost ldapserver19:tls]$ cat ca.conf 
basicConstraints = critical,CA:FALSE
extendedKeyUsage = serverAuth,emailProtection
```

### L'autoritat CA ha de firmar el certificat
[gustavo@localhost keys]$ openssl x509 -CA certif_CA.pem -CAkey key_CA.pem -req -in certif_server.pem -days 365 -sha1 -extfile ca.conf -CAcreateserial -out crt_server.pem
Signature ok
subject=C = ca, ST = Barcelona, L = Barcelona, O = M11-SAD, OU = Informatica, CN = ldap.edt.org, emailAddress = admin@edt.org
Getting CA Private Key

### Arxius Generats
```
[gustavo@localhost keys]$ ll
total 28
-rw-rw-r--. 1 gustavo gustavo   83 abr  6 19:42 ca.conf
-rw-rw-r--. 1 gustavo gustavo 1513 abr  6 19:59 certif_CA.pem
-rw-rw-r--. 1 gustavo gustavo   41 abr  6 20:33 certif_CA.srl
-rw-rw-r--. 1 gustavo gustavo 1135 abr  6 20:21 certif_server.pem
-rw-rw-r--. 1 gustavo gustavo 1436 abr  6 20:33 crt_server.pem
-rw-------. 1 gustavo gustavo 1675 abr  6 19:56 key_CA.pem
-rw-------. 1 gustavo gustavo 1679 abr  6 19:56 key_server.pem
```

# Configuració

## Fitxer slapd.conf
```
# Afegir abans de definir les databases, les següents lineas:
TLSCACertificateFile    /etc/openldap/certs/cacrt.pem
TLSCertificateFile      /etc/openldap/certs/servercrt.pem
TLSCertificateKeyFile   /etc/openldap/certs/serverkey.pem
TLSVerifyClient         never
TLSCipherSuite          HIGH:MEDIUM:LOW:+SSLv2
```

## Fitxer ldap.conf
```
# Comentar o eliminar la següent linea: 
TLS_CACERTDIR /etc/openldap/certs
# i canviarla per aquesta
TLS_CACERT /etc/openldap/certs/cacrt.pem

# Afegir al final
URI ldap://ldap.edt.org
BASE dc=edt,dc=org
---
```

## Fitxer startup.sh
```
# Afegir la següent linea
/sbin/slapd -d0 -h "ldap:/// ldaps:/// ldapi:///" 
```

cliente `ldap.conf`


TLS_CACERT /etc/ldap/cacrt.pem
TLS_REQCERT allow

URI ldap://ldap.edt.org
BASE dc=edt,dc=org

SASL_NOCANON on
```



# Comprovacions
```
ldapsearch -x -LLL -ZZ dn
ldapsearch -x -LLL -ZZ -h ldap.edt.org -b 'dc=edt,dc=org' dn
ldapsearch -x -LLL -H ldaps://ldap.edt.org dn
openssl s_client -connect ldap.edt.org:636
```



# Docker
```
docker run --rm --name ldap.edt.org -h ldap.edt.org -p 389:389  -p 636:636 -d isx43577298/ldapserver19:tls 
```


