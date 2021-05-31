#!/bin/bash
yum install -y bind bind-utils
systemctl start named
systemctl enable named

read -r -a array <<< $(ip addr |grep 192.168.1.17)
cat >> /etc/sysconfig/network-scripts/ifcfg-${array[7]} << EOF
GATEWAY=192.168.1.100
DNS1=192.168.1.17
DNS2=8.8.8.8
EOF

sed -i 's/search lab.local/search lab.local\nnameserver 192.168.1.17\nnameserver 8.8.8.8/g' /etc/resolv.conf


mv /etc/named.conf /etc/named.conf.bak
cat > /etc/named.conf << EOF
//
// named.conf
//
// Provided by Red Hat bind package to configure the ISC BIND named(8) DNS
// server as a caching only nameserver (as a localhost DNS resolver only).
//
// See /usr/share/doc/bind*/sample/ for example named configuration files.
//
// See the BIND Administrator's Reference Manual (ARM) for details about the
// configuration located in /usr/share/doc/bind-{version}/Bv9ARM.html

options {
        listen-on port 53 { 127.0.0.1;192.168.1.17;172.16.10.219; };
        listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        recursing-file  "/var/named/data/named.recursing";
        secroots-file   "/var/named/data/named.secroots";
        allow-query     { localhost;192.168.1.0/24;172.16.10.0/24; };

        /*
         - If you are building an AUTHORITATIVE DNS server, do NOT enable recursion. 
         - If you are building a RECURSIVE (caching) DNS server, you need to enable  
           recursion.
         - If your recursive DNS server has a public IP address, you MUST enable access
           control to limit queries to your legitimate users. Failing to do so will  
           cause your server to become part of large scale DNS amplification
           attacks. Implementing BCP38 within your network would greatly
           reduce such attack surface
        */
        recursion yes;

        dnssec-enable yes;
        dnssec-validation yes;

        /* Path to ISC DLV key */
        bindkeys-file "/etc/named.root.key";

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

zone "." IN {
        type hint;
        file "named.ca";
};
// Forward Zone
zone "lab.local" IN {                   // Domain name
        type master;                    // Primary DNS
        file "forward.lab.local";       // Forward lookup file
        allow-update { none; };         // allow-update – Since this is the primary DNS, it should be none
};

// Reverse Zone
zone "1.168.192.in-addr.arpa" IN {      // 1.168.192.in-addr.arpa – Reverse lookup name
        type master;                    // master – Primary DNS
        file "reverse.lab.local";       // Reverse lookup file
        allow-update { none; };         // Since this is the primary DNS, it should be none
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
EOF

cd /var/named
cat > forward.lab.local << EOF
@       IN      SOA     dns1.lab.local  root.lab.local. (
                        1001    ;Serial
                        3H      ;Refresh
                        15M     ;Retry
                        1W      ;Exprie
                        1D      ;Minimum TTL
)
;Name Server Information
@       IN      NS      dns1.lab.local. ; NS : Name Server
;A - Record Hostname to IP Address
dns1    IN      A       192.168.1.17    ; A - A Record ( DNS Server )
www     IN      A       172.16.10.220   ; A - A Record ( www Server )
mail    IN      A       172.16.10.221   ; A - A Record ( Mail Server )
;Mail Exchanger
lab.local.      IN      MX      10      mail.lab.local. ; MX - Mail for Exchange     
;CNAME  record
ftp     IN      CNAME   www.lab.local.          ; CNAME – Canonical Name

EOF


cat > reverse.lab.local << EOF
@       IN      SOA     dns1.lab.local. root.lab.local. (
                        1001    ;Serial
                        3H      ;Refresh
                        15M     ;Retry
                        1W      ;Expire
                        1D      ;Minium TTL
)
;Name Server Information
@       IN      NS      dns1.lab.local.
;PTR Record IP address to Hostname
8       IN      PTR     dns1.lab.local. ; Pointer 172.16.10.219 to dns1.lab.local    
9       IN      PTR     www.lab.local.  ; Pointer 172.16.10.220 to www.lab.local     
10      IN      PTR     mail.lab.local. ; Pointer 172.16.10.221 to mail.lab.local

EOF

systemctl restart named