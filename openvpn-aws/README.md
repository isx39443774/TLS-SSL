# OPENVPN amb certificats propis

## Creació de certificats i claus

### Servidor

Primer hem de generar la clau privada, per posteriorment generar el CA.

```
fedora@ip-172-31-31-251 ~]$ openssl genrsa -out server_key.pem
Generating RSA private key, 2048 bit long modulus (2 primes)
....+++++
.................+++++
e is 65537 (0x010001)
```

Ara generem el request
```
[fedora@ip-172-31-31-251 ~]$ openssl req -new -x509 -nodes -sha1 -days 365 -key ca_key.pem -out ca_certif.pem
Enter pass phrase for ca_key.pem:
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
Organizational Unit Name (eg, section) []:Certificat
Common Name (eg, your name or your server's hostname) []:Veritat Absoluta
Email Address []:admin@edt.org
```
```
[fedora@ip-172-31-31-251 ~]$ openssl req -new -key server_key.pem -out server_req.pe
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

## Creació i certificació de CA

Creem un CA anomenat extern.ca.conf, el qual contindrà:
```
basicConstraints       = CA:FALSE
nsCertType             = server
nsComment              = "OpenSSL Generated Server Certificate"
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid,issuer:always
extendedKeyUsage       = serverAuth
keyUsage               = digitalSignature, keyEncipherment
```

Generació del certificat

```
[fedora@ip-172-31-31-251 ~]$ openssl x509 -CA ca_certif.pem -CAkey ca_key.pem -req -in server_req.pem -days 365 -sha1 -extfile extern.ca.conf -CAcreateserial -out crt_server.pem
Signature ok
subject=C = ca, ST = Barcelona, L = Barcelona, O = M11, OU = Dep. Informatica, CN = ldap.edt.org, emailAddress = admin@edt.org
Getting CA Private Key
```

### Client
El que farem ha continuació s'ha de reproduir per a cada client, ja que cada client ha de tenir la seva clau propia.

#### Generar clau client i request per la CA
```
[root@localhost client]# openssl genrsa -out key_clie1.pem 2048
Generating RSA private key, 2048 bit long modulus (2 primes)
..................+++++
......................................................+++++
e is 65537 (0x010001)
```
```
root@localhost client]# openssl req -new -key key_clie1.pem -out req_clie1.pem
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
Organization Name (eg, company) [Default Company Ltd]:Client 1
Organizational Unit Name (eg, section) []:Client1
Common Name (eg, your name or your server's hostname) []:Client1
Email Address []:client1@client1.org

Please enter the following 'extra' attributes
to be sent with your certificate request
A challenge password []:jupiter
An optional company name []:edt
```

### Certificació de CA externa
Crearem un fitxer anomenat extern.client.conf, que sera la nostre CA externa. amb el següent contingut:
```
basicConstraints        = CA:FALSE
subjectKeyIdentifier    = hash
authorityKeyIdentifier  = keyid,issuer:always
```

Generem certificat pel Client1
```
[root@localhost client]$ openssl x509 -CAkey ca_key.pem -CA ca_certif.pem -req -in req_clie1.pem -days 365 -CAcreateserial -extfile extern.client.conf -out certif_clie1.pem
Signature ok
subject=C = ca, ST = Barcelona, L = Barcelona, O = Client 1, OU = Client1, CN = Client1
Getting CA Private Key
```

## Activació dels serveis

Com que el nostre servidor es troba a AWS hem de recordar d'obrir els ports corresponents des de el security groups.

* Engegem el servei del servidor
```
[fedora@ip-172-31-31-251 ~]$ sudo systemctl start openvpn-server@server.service
```

* Engegem el servei del client
```
[root@localhost client]$ sudo systemctl start openvpn-client@confclient.service
```

## Comprovació del tunel

Farem servir la comanda ip per comprovar que s'ha creat correctament la vpn.

```
[root@localhost client]$ sudo ip a
8: tun0: <POINTOPOINT,MULTICAST,NOARP,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UNKNOWN group default qlen 100
    link/none
    inet 10.8.0.6 peer 10.8.0.5/32 scope global tun0
       valid_lft forever preferred_lft forever
    inet6 fe80::7df:1c59:e502:1058/64 scope link stable-privacy
       valid_lft forever preferred_lft forever
```

Ping client a servidor
```
[root@localhost client]$ ping 10.8.0.1
PING 10.8.0.1 (10.8.0.1) 56(84) bytes of data.
64 bytes from 10.8.0.1: icmp_seq=1 ttl=64 time=146 ms
64 bytes from 10.8.0.1: icmp_seq=2 ttl=64 time=125 ms
64 bytes from 10.8.0.1: icmp_seq=3 ttl=64 time=182 ms
```
Ping servidor a client
```
[fedora@ip-172-31-31-251 ~]$ ping 10.8.0.6
PING 10.8.0.6 (10.8.0.6) 56(84) bytes of data.
64 bytes from 10.8.0.6: icmp_seq=1 ttl=64 time=162 ms
64 bytes from 10.8.0.6: icmp_seq=2 ttl=64 time=186 ms
64 bytes from 10.8.0.6: icmp_seq=3 ttl=64 time=210 ms
```
