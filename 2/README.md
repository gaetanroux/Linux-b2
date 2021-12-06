# TP2 pt. 1 : Gestion de service



| Machine         | IP            | Service                 | Port ouvert | IP autorisées |
|-----------------|---------------|-------------------------|-------------|---------------|
| `web.tp2.linux` | `10.102.1.11` | Serveur Web             | `80`          | `10.102.1.12`             |
| `db.tp2.linux`  | `10.102.1.12` | Serveur Base de Données | `3306`           | `10.102.1.11`             |

- 🌞 **Installer le serveur Apache**
- paquet `httpd`

`[gaetan@web ~]$ sudo dnf install httpd`

- le fichier de conf principal est `/etc/httpd/conf/httpd.conf`


`[gaetan@web ~]$ sudo vim /etc/httpd/conf/httpd.conf`

```
[gaetan@web ~]$ cat /etc/httpd/conf/httpd.conf

ServerRoot "/etc/httpd"

Listen 80

Include conf.modules.d/*.conf

User apache
Group apache


ServerAdmin root@localhost


<Directory />
    AllowOverride none
    Require all denied
</Directory>


DocumentRoot "/var/www/html"

<Directory "/var/www">
    AllowOverride None
    Require all granted
</Directory>

<Directory "/var/www/html">
    Options Indexes FollowSymLinks

    AllowOverride None

    Require all granted
</Directory>

<IfModule dir_module>
    DirectoryIndex index.html
</IfModule>

<Files ".ht*">
    Require all denied
</Files>

ErrorLog "logs/error_log"

LogLevel warn

<IfModule log_config_module>
    LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
    LogFormat "%h %l %u %t \"%r\" %>s %b" common

    <IfModule logio_module>
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
    </IfModule>


    CustomLog "logs/access_log" combined
</IfModule>

<IfModule alias_module>


    ScriptAlias /cgi-bin/ "/var/www/cgi-bin/"

</IfModule>

<Directory "/var/www/cgi-bin">
    AllowOverride None
    Options None
    Require all granted
</Directory>

<IfModule mime_module>
    TypesConfig /etc/mime.types

    AddType application/x-compress .Z
    AddType application/x-gzip .gz .tgz



    AddType text/html .shtml
    AddOutputFilter INCLUDES .shtml
</IfModule>

AddDefaultCharset UTF-8

<IfModule mime_magic_module>
    MIMEMagicFile conf/magic
</IfModule>


EnableSendfile on

IncludeOptional conf.d/*.conf
```


- 🌞 **Démarrer le service Apache**

- démarrez le
`[gaetan@web ~]$ sudo systemctl enable --now httpd.service`

- faites en sorte qu'Apache démarre automatique au démarrage de la machine
` sudo systemctl enable httpd`

- ouvrez le port firewall nécessaire

```
[gaetan@web ~]$ sudo firewall-cmd --add-port=80/tcp --permanent
success
```
```
[gaetan@web ~]$ sudo firewall-cmd --reload
success
```
- utiliser une commande `ss` pour savoir sur quel port tourne actuellement Apache
```
[gaetan@web ~]$ sudo ss -alnpt
State           Recv-Q          Send-Q                   Local Address:Port                   Peer Address:Port         Process
[...]
LISTEN          0               128                                  *:80                                *:*             users:(("httpd",pid=2090,fd=4),("httpd",pid=2089,fd=4),("httpd",pid=2088,fd=4),("httpd",pid=2086,fd=4))
[...]
```


- 🌞 **TEST***

- vérifier que le service est démarré
```
[gaetan@web ~]$ sudo service httpd status
[sudo] password for gaetan:
Redirecting to /bin/systemctl status httpd.service
● httpd.service - The Apache HTTP Server
   Loaded: loaded (/usr/lib/systemd/system/httpd.service; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-09-29 15:59:41 CEST; 12min ago
```
- vérifier qu'il est configuré pour démarrer automatiquement
```
[gaetan@web ~]$ sudo systemctl is-enabled httpd
[sudo] password for gaetan:
enabled
```
- vérifier avec une commande `curl localhost` que vous joignez votre serveur web localement
```
[gaetan@web ~]$ curl localhost
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
      /*<![CDATA[*/
      
      
[...]
```
- vérifier avec votre navigateur (sur votre PC) que vous accéder à votre serveur web
```
PS C:\Users\gaeta> curl 10.102.1.11:80
curl : HTTP Server Test Page
This page is used to test the proper operation of an HTTP server after it has been installed on a Rocky Linux system.
If you can read this page, it means that the software it working correctly.
Just visiting?
This website you are visiting is either experiencing problems or could be going through maintenance.
If you would like the let the administrators of this website know that you've seen this page instead of the page
you've expected, you should send them an email. In general, mail sent to the name "webmaster" and [...]
```




## 2. Avancer vers la maîtrise du service

- 🌞 **Le service Apache...**

- donnez la commande qui permet d'activer le démarrage automatique d'Apache quand la machine s'allume

`sudo systemctl enable httpd`
- prouvez avec une commande qu'actuellement, le service est paramétré pour démarré quand la machine s'allume

`sudo systemctl is-enabled httpd`

- affichez le contenu du fichier `httpd.service` qui contient la définition du service Apache

```
[gaetan@web ~]$ cat /usr/lib/systemd/system/httpd.service
# See httpd.service(8) for more information on using the httpd service.

# Modifying this file in-place is not recommended, because changes
# will be overwritten during package upgrades.  To customize the
# behaviour, run "systemctl edit httpd" to create an override unit.

# For example, to pass additional options (such as -D definitions) to
# the httpd binary at startup, create an override unit (as is done by
# systemctl edit) and enter the following:

#       [Service]
#       Environment=OPTIONS=-DMY_DEFINE

[Unit]
Description=The Apache HTTP Server
Wants=httpd-init.service
After=network.target remote-fs.target nss-lookup.target httpd-init.service
Documentation=man:httpd.service(8)

[Service]
Type=notify
Environment=LANG=C

ExecStart=/usr/sbin/httpd $OPTIONS -DFOREGROUND
ExecReload=/usr/sbin/httpd $OPTIONS -k graceful
# Send SIGWINCH for graceful stop
KillSignal=SIGWINCH
KillMode=mixed
PrivateTmp=true

[Install]
WantedBy=multi-user.target
```

- 🌞 **Déterminer sous quel utilisateur tourne le processus Apache**

- mettez en évidence la ligne dans le fichier de conf qui définit quel user est utilisé

`[gaetan@web ~]$ cat /etc/httpd/conf/httpd.conf`

`User apache`
- utilisez la commande `ps -ef` pour visualiser les processus en cours d'exécution et confirmer que apache tourne bien sous l'utilisateur mentionné dans le fichier de conf

```
[gaetan@web ~]$ ps -ef | grep apache
apache      2087    2086  0 15:59 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      2088    2086  0 15:59 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      2089    2086  0 15:59 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
apache      2090    2086  0 15:59 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
gaetan      2468    1537  0 16:50 pts/0    00:00:00 grep --color=auto apache
```

- vérifiez avec un `ls -al` le dossier du site (dans `/var/www/...`) 
- vérifiez que tout son contenu appartient à l'utilisateur mentionné dans le fichier de conf

```
[gaetan@web www]$ ls -al
total 4
drwxr-xr-x.  4 root root   33 Sep 29 15:55 .
drwxr-xr-x. 22 root root 4096 Sep 29 15:55 ..
drwxr-xr-x.  2 root root    6 Jun 11 17:35 cgi-bin
drwxr-xr-x.  2 root root    6 Jun 11 17:35 html
```

- 🌞 **Changer l'utilisateur utilisé par Apache**

- créez le nouvel utilisateur
`[gaetan@web ~]$ sudo adduser toto -m -d /home/toto -s /bin/bash`

- pour les options de création, inspirez-vous de l'utilisateur Apache existant
- le fichier `/etc/passwd` contient les informations relatives aux utilisateurs existants sur la machine
- servez-vous en pour voir la config actuelle de l'utilisateur Apache par défaut

`[gaetan@web ~]$ cat /etc/passwd`
```
apache:x:48:48:Apache:/usr/share/httpd:/sbin/nologin
toto:x:1001:1001::/home/toto:/bin/bash
```
`après` 
```
apache:x:48:48:Apache:/usr/share/httpd:/sbin/nologin
toto:x:48:48::/home/toto:/bin/bas
```

- modifiez la configuration d'Apache pour qu'il utilise ce nouvel utilisateur
`sudo nano /etc/httpd/conf/httpd.conf`

`User toto`
- redémarrez Apache

`[gaetan@web ~]$ systemctl restart httpd`

- utilisez une commande `ps` pour vérifier que le changement a pris effet
```
[gaetan@web ~]$ ps -ef | grep toto
toto        2823    2822  0 17:10 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
toto        2824    2822  0 17:10 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
toto        2825    2822  0 17:10 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
toto        2826    2822  0 17:10 ?        00:00:00 /usr/sbin/httpd -DFOREGROUND
gaetan      3046    2500  0 17:12 pts/0    00:00:00 grep --color=auto toto
```

- 🌞 **Faites en sorte que Apache tourne sur un autre port**

- modifiez la configuration d'Apache pour lui demande d'écouter sur un autre port
`sudo nano /etc/httpd/conf/httpd.conf`

`Listen 08`

- ouvrez un nouveau port firewall, et fermez l'ancien
```
[gaetan@web ~]$ sudo firewall-cmd --add-port=08/tcp --permanent
success
[gaetan@web ~]$ sudo firewall-cmd --reload
success
```
```
[gaetan@web ~]$ sudo firewall-cmd --remove-port=80/tcp --permanent
success
```
- redémarrez Apache
`[gaetan@web ~]$ systemctl restart httpd`
- prouvez avec une commande `ss` que Apache tourne bien sur le nouveau port choisi
```
[gaetan@web ~]$ sudo ss -alnpt
State           Recv-Q          Send-Q                   Local Address:Port                   Peer Address:Port         Process
[...]
LISTEN          0               128                                  *:8                                 *:*             users:(("httpd",pid=3097,fd=4),("httpd",pid=3096,fd=4),("httpd",pid=3095,fd=4),("httpd",pid=3092,fd=4))
[...]
```

- vérifiez avec `curl` en local que vous pouvez joindre Apache sur le nouveau port
```
[gaetan@web ~]$ curl localhost:08
<!doctype html>
<html>
  <head>
    <meta charset='utf-8'>
    <meta name='viewport' content='width=device-width, initial-scale=1'>
    <title>HTTP Server Test Page powered by: Rocky Linux</title>
    <style type="text/css">
```
- vérifiez avec votre navigateur que vous pouvez joindre le serveur sur le nouveau port
```
PS C:\Users\gaeta> curl 10.102.1.11:08
curl : HTTP Server Test Page
This page is used to test the proper operation of an HTTP server after it has been installed on a Rocky Linux system.
If you can read this page, it means that the software it working correctly.
Just visiting?
This website you are visiting is either experiencing problems or could be going through maintenance.
If you would like the let the administrators of this website know that you've seen this page instead of the page
you've expected, you should send them an email. In general, mail sent to the name "webmaster" and directed to the
website's domain should reach the appropriate person.
The most common email address to send to is: "webmaster@example.com"
```

📁 **Fichier `/etc/httpd/conf/httpd.conf`**


# II. Une stack web plus avancée

## 1. Intro
### A. Serveur Web et NextCloud

**Créez les 2 machines et déroulez la [📝**checklist**📝](#checklist).**

- 🌞 Install du serveur Web et de NextCloud sur `web.tp2.linux`

```
   16  sudo wget https://download.nextcloud.com/server/releases/nextcloud-22.2.0.zip
   17  wget https://download.nextcloud.com/server/releases/nextcloud-22.2.0.zip
   18  sudo dnf install wget
   19  wget https://download.nextcloud.com/server/releases/nextcloud-22.2.0.zip
   20  sudo dnf install epel-release
   21  sudo dnf update
   22  sudo dnf install https://rpms.remirepo.net/enterprise/remi-release-8.rpm
   23  sudo dnf module list php
   24  sudo dnf module enable php:remi-7.4
   25  sudo dnf module list php
   26  sudo dnf install httpd mariadb-server vim wget zip unzip libxml2 openssl php74-php php74-php-ctype php74-php-curl php74-php-gd php74-php-iconv php74-php-json php74-php-libxml php74-php-mbstring php74-php-openssl php74-php-posix php74-php-session php74-php-xml php74-php-zip php74-php-zlib php74-php-pdo php74-php-mysqlnd php74-php-intl php74-php-bcmath php74-php-gmp
   27  sudo systemctl enable httpd
   28  sudo dnf install httpd php
   29  vi /etc/httpd/httpd.conf
   30  vi /etc/httpd
   31  cd /etc/httpd/
   32  ls
   33  sudo nano /conf
   34  cd /conf
   35  sudo nano conf
   36  cd ..
   37  cd /etc/httpd/conf/httpd.conf
   38  cd nano /etc/httpd/conf/httpd.conf
   39  sudo nano /etc/httpd/conf/httpd.conf
   40  cd /home/gaetan/
   41  sudo mkdir /etc/httpd/sites-available
   42  sudo mkdir /etc/httpd/sites-enabled
   43  cd /etc/httpd/sites-available/
   44  pwd
   45  cd ..
   46  cd /home/gaetan/
   47  sudo mkdir /var/www/sub-domains/
   48  sudo /etc/httpd/sites-available/linux.tp3.web
   49  sudo nano /etc/httpd/sites-available/linux.tp3.web
   50  rm linux.tp3.web
   51  cd /etc/httpd/sites-available/
   52  ls -all
   53  cd ..
   54  cd /home/gaetan/
   55  sudo nano /etc/httpd/sites-available/linux.tp2.web
   56  sudo mkdir -p /var/www/sub-domains/linux.tp2.web/html
   57  sudo cp -Rf web_source/* /var/www/sub-domains/linux.tp2.web/html/
   58  sudo cp -Rf wiki_source/* /var/www/sub-domains/linux.tp2.web/html/
   59  sudo cp -Rf /etc/httpd/sites-available/ /var/www/sub-domains/linux.tp2.web/html/
   60  sudo vi /etc/httpd/sites-available/linux.tp2.web
   61  sudo vi /etc/httpd/sites-available/linux.tp2.nextcloud
   62  sudo vi /etc/httpd/sites-available/linux.tp2.web
   63  sudo ln -s /etc/httpd/sites-available/linux.tp2.web /etc/httpd/sites-enabled/
   64  sudo mkdir -p /var/www/sub-domains/linux.tp2.web/html
   65  timedatectl
   66  sudo vi /etc/opt/remi/php74/php.ini
   67  sudo vi /etc/opt/remi/php74/php.ini | grep timez
   68  jobs -p
   69  kill 6616
   70  sudo kill 6616
   71  sudo cat /etc/opt/remi/php74/php.ini | grep timez
   72  sudo cat /etc/opt/remi/php74/php.ini | grep timez -n
   73  sudo vim /etc/opt/remi/php74/php.ini
   74  sudo vi /etc/opt/remi/php74/php.ini
   75  ls -al /etc/localtime
   76  wget https://download.nextcloud.com/server/releases/nextcloud-22.2.0.zip
   77  unzip nextcloud-21.0.1.zip
   78  unzip nextcloud-22.2.0.zip
   79  cd nextcloud
   80  cp -Rf * /var/www/sub-domains/linux.tp2.web/html/
   81  sudo cp -Rf * /var/www/sub-domains/linux.tp2.web/html/
   82  sudo chown -Rf apache.apache /var/www/sub-domains/linux.tp2.web/html
   83  mv /var/www/sub-domains/linux.tp2.web/html/data /var/www/sub-domains/linux.tp2.web/
   84  mv /var/www/sub-domains/linux.tp2.web/html/ /var/www/sub-domains/linux.tp2.web/
   85  mv /var/www/sub-domains/linux.tp2.web/html /var/www/sub-domains/linux.tp2.web/
   86  mv /var/www/sub-domains/linux.tp2.web/html/data /var/www/sub-domains/linux.tp2.web/
   87  cd ..
   88  mkdir /var/www/sub-domains/linux.tp2.web/html/data
   89  sudo mkdir /var/www/sub-domains/linux.tp2.web/html/data
   90  mv /var/www/sub-domains/linux.tp2.web/html/data /var/www/sub-domains/linux.tp2.web/
   91  sudo mv /var/www/sub-domains/linux.tp2.web/html/data /var/www/sub-domains/linux.tp2.web/
   92  systemctl restart httpd
   93  systemctl restart mariadb
   94  curl web.tp2.linux:80
   95  curl 10.102.1.11
   96  curl 10.102.1.11:80
   97  ip a
   98  curl web.tp2.linux
   99  sudo systemctl status httpd
  100  sudo cat /var/log/httpd/error_log
  101  sestatus
  102  sudo cat /var/log/httpd/error_log
  103  cd /etc/httpd/
  104  ls sites-available/ -azl
  105  ls sites-available/ -al
  106  ls sites-enabled/
  107  ls sites-enabled/ -al
  108  cat conf/httpd.conf
  109  cat sites-enabled/linux.tp2.web
  110  sudo vim sites-enabled/linux.tp2.web
  111  sudo systemctl restart httpd
  112  sudo cat /var/log/httpd/error_log
  113  sudo cat /var/log/httpd/access_log
  114  dnf module list php
  115  sudo dnf install httpd mariadb-server vim wget zip unzip libxml2 openssl php74-php php74-php-ctype php74-php-curl php74-php-gd php74-php-iconv php74-php-json php74-php-libxml php74-php-mbstring php74-php-openssl php74-php-posix php74-php-session php74-php-xml php74-php-zip php74-php-zlib php74-php-pdo php74-php-mysqlnd php74-php-intl php74-php-bcmath php74-php-gmp -y
  116  sudo vi /etc/opt/remi/php74/php.ini
  117  sudo rm /etc/opt/remi/php74/.php.ini.swp
  118  sudo vi /etc/opt/remi/php74/php.ini
  119  sudo systemctl restart httpd
  120  sudo dnf install httpd mariadb-server vim wget zip unzip libxml2 openssl php74-php php74-php-ctype php74-php-curl php74-php-gd php74-php-iconv php74-php-json php74-php-libxml php74-php-mbstring php74-php-openssl php74-php-posix php74-php-session php74-php-xml php74-php-zip php74-php-zlib php74-php-pdo php74-php-mysqlnd php74-php-intl php74-php-bcmath php74-php-gmp -y
  121  sudo vi /etc/opt/remi/php74/php.ini
  122  sudo systemctl restart httpd
  123  sudo cat /var/log/httpd/access_log
  124  sudo systemctl restart httpd
  125  sudo cat /var/log/httpd/error_log
  126  sestatus
  127  ls -al /var/opt/remi/php74/run/php-fpm/www.sock
  128  sudo chown httpd:httpd /var/opt/remi/php74/run/php-fpm/www.sock
  129  cat /etc/passwd
  130  sudo chown apache:apache /var/opt/remi/php74/run/php-fpm/www.sock
  131  sudo systemctl restart httpd
```

📁 **Fichier `/etc/httpd/conf/httpd.conf`**  
📁 **Fichier `/etc/httpd/conf/sites-available/web.tp2.linux`**

### B. Base de données

🌞 **Install de MariaDB sur `db.tp2.linux`**


- je veux dans le rendu **toutes** les commandes réalisées
```
   26  sudo dnf install mariadb-server
   27  sudo systemctl enable mariadb
   28  systemctl start mariadb
   29  mysql_secure_installation
```

 
- vous repérerez le port utilisé par MariaDB avec une commande `ss` exécutée sur `db.tp2.linux`
```
[gaetan@db ~]$ sudo ss -alnpt
State        Recv-Q       Send-Q             Local Address:Port             
LISTEN       0            80                             *:3306                        *:*          users:(("mysqld",pid=26265,fd=21))
```


- 🌞 **Préparation de la base pour NextCloud**

  - connectez-vous à la base de données à l'aide de la commande `sudo mysql -u root`

- exécutez les commandes SQL suivantes :
```
MariaDB [(none)]> CREATE USER 'nextcloud'@'10.102.1.11' IDENTIFIED BY 'root';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> CREATE DATABASE IF NOT EXISTS nextcloud CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
Query OK, 1 row affected (0.001 sec)

MariaDB [(none)]> GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'10.102.1.11';
Query OK, 0 rows affected (0.001 sec)

MariaDB [(none)]> FLUSH PRIVILEGES;
Query OK, 0 rows affected (0.001 sec)
```


- 🌞 **Exploration de la base de données**

- vous pouvez utiliser la commande `mysql` pour vous connecter à une base de données depuis la ligne de commande
    - par exemple `mysql -u <USER> -h <IP_DATABASE> -p`

```
[gaetan@web ~]$ mysql -u nextcloud -h 10.102.1.12 -p
Enter password:
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 10
Server version: 10.3.28-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]>
```

- utilisez les commandes SQL fournies ci-dessous pour explorer la base

```

MariaDB [(none)]> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| nextcloud          |
+--------------------+
2 rows in set (0.002 sec)

MariaDB [(none)]> USE nextcloud;
Database changed
MariaDB [nextcloud]> SHOW TABLES;
Empty set (0.001 sec)
```

- trouver une commande qui permet de lister tous les utilisateurs de la base de données
```
MariaDB [(none)]> SELECT User, Host FROM mysql.user;
+-----------+-------------+
| User      | Host        |
+-----------+-------------+
| nextcloud | 10.102.1.11 |
| root      | 127.0.0.1   |
| root      | ::1         |
| root      | localhost   |
+-----------+-------------+
```



### C. Finaliser l'installation de NextCloud

🌞 **sur votre PC**
- modifiez votre fichier `hosts` (oui, celui de votre PC, de votre hôte)

`C:\Windows\System32\drivers\etc`

`fichier host ducoup` 

`ajout d'une ligne : 10.102.11 web.tp2.linux`

- saisissez l'identifiant et le mot de passe admin que vous voulez, et validez l'installation

`whoahhhh c'est beau !`

🌞 **Exploration de la base de données**

- connectez vous en ligne de commande à la base de données après l'installation terminée
- déterminer combien de tables ont été crées par NextCloud lors de la finalisation de l'installation

`Il y en a beaucoupp !`

`SHOW TABLES;`
  - ***bonus points*** si la réponse à cette question est automatiquement donnée par une requête SQL

