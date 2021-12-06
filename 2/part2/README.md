# TP2 pt. 2 : Maintien en condition opérationnelle



# I. Monitoring

On bouge pas pour le moment niveau machines :

| Machine         | IP            | Service                 | Port ouvert | IPs autorisées |
|-----------------|---------------|-------------------------|-------------|---------------|
| `web.tp2.linux` | `10.102.1.11` | Serveur Web             | `80`     | ?             |
| `db.tp2.linux`  | `10.102.1.12` | Serveur Base de Données | `80 3306`    | ?             |

## 2. Setup
🌞 **Setup Netdata**
```
# Passez en root pour cette opération
$ sudo su -

# Install de Netdata via le script officiel statique
$ bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh)

# Quittez la session de root
$ exit
```

- 🌞 **Manipulation du *service* Netdata**

[gaetan@web ~]$ ss -alnpt
State          Recv-Q         Send-Q                  Local Address:Port                    Peer Address:Port         Process
[...]
LISTEN         0              128                              [::]:19999                           [::]:*

```
[gaetan@web ~]$ systemctl status netdata.service
● netdata.service - Real time performance monitoring
   Loaded: loaded (/usr/lib/systemd/system/netdata.service; enabled; vendor preset: disabled)
   Active: active (running) since Mon 2021-10-11 14:42:19 CEST; 1h 9min ago
  Process: 2164 ExecStartPre=/bin/chown -R netdata:netdata /opt/netdata/var/run/netdata (code=exited, status=0/SUCCESS)
  Process: 2162 ExecStartPre=/bin/mkdir -p /opt/netdata/var/run/netdata (code=exited, status=0/SUCCESS)
  Process: 2160 ExecStartPre=/bin/chown -R netdata:netdata /opt/netdata/var/cache/netdata (code=exited, status=0/SUCCESS)
  Process: 2159 ExecStartPre=/bin/mkdir -p /opt/netdata/var/cache/netdata (code=exited, status=0/SUCCESS)
 Main PID: 2166 (netdata)
    Tasks: 35 (limit: 4946)
   Memory: 75.8M
   CGroup: /system.slice/netdata.service
           ├─2166 /opt/netdata/bin/srv/netdata -P /opt/netdata/var/run/netdata/netdata.pid -D
           ├─2176 /opt/netdata/bin/srv/netdata --special-spawn-server
           ├─2339 /opt/netdata/usr/libexec/netdata/plugins.d/go.d.plugin 1
           └─2346 /opt/netdata/usr/libexec/netdata/plugins.d/apps.plugin 1
```

`[gaetan@web ~]$ sudo systemctl enable netdata.service`

```
[gaetan@web ~]$ curl http://10.102.1.12:19999
`[...]l-title" id="gotoServerModalLabel"><span id="gotoServerName"></span></h4></div><div class="modal-body">Checking known URLs for this server...<div style="padding-top:20px"><table id="gotoServerList"></table></div><p style="padding-top:10px"><small>Checks may fail if you are viewing an HTTPS page and the server to be checked is HTTP only.</small></p><div id="gotoServerResponse" style="display:block;width:100%;text-align:center;[....]`
```

- 🌞 **Setup Alerting**

```
[gaetan@web ~]$ sudo /opt/netdata/etc/netdata/edit-config health_alarm_notify.conf
Copying '/opt/netdata/usr/lib/netdata/conf.d/health_alarm_notify.conf' to '/opt/netdata/etc/netdata/health_alarm_notify.conf' ...
Editing '/opt/netdata/etc/netdata/health_alarm_notify.conf' ...
```
`[gaetan@web ~]$ sudo vi /opt/netdata/etc/netdata/health_alarm_notify.conf`

- modifier cette partie du fichier de configuration.
`DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/897105457062232074/OFaLJoOflWbYQqi1I4qeuG0U-GlPDVd_gpLJ7uElJNMoCXfh1x7GUt6a7OJWZQqZixCa"`

`[gaetan@web ~]$ su -s /bin/bash gaetan`
`[gaetan@web ~]$ export NETDATA_ALARM_NOTIFY_DEBUG=1`
`[gaetan@web ~]$ /opt/netdata/usr/libexec/netdata/plugins.d/alarm-notify.sh test`
`[gaetan@backup ~]$ sudo sed -i 's/curl=""/curl="\/opt\/netdata\/bin\/curl -k"/' /opt/netdata/etc/netdata/health_alarm_notify.conf`

- 🌞 **Config alerting**

`[gaetan@backup ~]$ cd /opt/netdata/etc/netdata/`
`[gaetan@backup netdata]$ sudo ./edit-config health.d/ram.conf`

- edit dans le fichier -- ram.conf :
```
     warn: $this > (($status >= $WARNING)  ? (50) : (70))
     crit: $this > (($status == $CRITICAL) ? (70) : (98))
```
`[gaetan@web netdata]$ sudo stress --vm 4 --vm-bytes 1024M`

# II. Backup

| Machine            | IP            | Service                 | Port ouvert | IPs autorisées |
|--------------------|---------------|-------------------------|-------------|---------------|
| `web.tp2.linux`    | `10.102.1.11` | Serveur Web             | `80`           | ?             |
| `db.tp2.linux`     | `10.102.1.12` | Serveur Base de Données | `80 3306 19999`          | ?             |
| `backup.tp2.linux` | `10.102.1.13` | Serveur de Backup (NFS) | ?           | ?             |

## 2. Partage NFS

- 🌞 **Setup environnement**

`[gaetan@backup ~]$ mkdir /srv/backup/`
`[gaetan@backup backup]$ mkdir /srv/backup/web.tp2.linux/`

- 🌞 **Setup partage NFS**

- 🌞 **Setup points de montage sur `web.tp2.linux`**
`[gaetan@web ~]$ sudo mount -t nfs backup.tp2.linux:/srv/backup/web.tp2.linux /srv/backup/`
```
[gaetan@web ~]$ mount | grep "srv"
backup.tp2.linux:/srv/backup/web.tp2.linux on /srv/backup type nfs4 (rw,relatime,vers=4.2,rsize=131072,wsize=131072,namlen=255,hard,proto=tcp,timeo=600,retrans=2,sec=sys,clientaddr=10.102.1.11,local_lock=none,addr=10.102.1.13)
```
```
[gaetan@web ~]$ df -h
[....]
backup.tp2.linux:/srv/backup/web.tp2.linux  6.2G  2.2G  4.1G  35% /srv/backup
```
```
[gaetan@web backup]$ touch texttest.txt
[gaetan@web backup]$ ls -all
total 0
drwxrwxrwx. 2 root   root   42 Oct 12 15:16 .
drwxr-xr-x. 3 root   root   20 Oct 11 17:55 ..
-rw-r--r--. 1 root   root    0 Oct 11 19:21 test.txt
-rw-rw-r--. 1 gaetan gaetan  0 Oct 12 15:16 texttest.txt
```
`[gaetan@backup ~]$ vi /etc/fstab`
`backup.tp2.linux:/srv/backup/web.tp2.linux /srv/backup          nfs     defaults        0 0`

🌟 **BONUS** : partitionnement avec LVM

`On creer un disque de 5GO depuis Vbox.`
```
[gaetan@backup ~]$ sudo pvcreate /dev/sdb
[sudo] password for gaetan:
  Physical volume "/dev/sdb" successfully created.
````
```
[gaetan@backup ~]$ cat /etc/fstab
[...]
/srv/backup/ /dev/sdb/                  nfs             defaults                0 0
```


## 3. Backup de fichiers

- 🌞 **Rédiger le script de backup `/srv/tp2_backup.sh`**

📁 **Fichier `/srv/tp2_backup.sh`**


- 🌞 **Tester le bon fonctionnement**
```
[gaetan@backup backup]$ sudo ./tp2_linux.sh /srv/backup/web.tp2.linux/ /home/gaetan/dossiertest/
[OK] Archive /srv/backup/tp2_backup_211013_190036.tar.gz created.
[OK] Archive /srv/backup/tp2_backup_211013_190036.tar.gz synchronized to /srv/backup/web.tp2.linux/.
[OK] Directory /srv/backup/web.tp2.linux/ cleaned to keep only the 5 most recent backups.
[gaetan@backup backup]$ cd web.tp2.linux/
```
```
[gaetan@backup web.tp2.linux]$ ls
tp2_backup_211013_190036.tar.gz
```
```
[gaetan@backup web.tp2.linux]$ sudo tar -xvzf tp2_backup_211013_190036.tar.gz
[sudo] password for gaetan:
home/gaetan/dossiertest/
home/gaetan/dossiertest/toto.txt
```


## 4. Unité de service

### A. Unité de service

- 🌞 **Créer une *unité de service*** pour notre backup
```
[gaetan@backup system]$ cat tp2_backup.service
[Unit]
Description=Script Backup et compression

[Service]
ExecStart=/srv/backup/tp2_backup.sh /srv/backup/web.tp2.linux/ /home/gaetan/dossiertest/
Type=oneshot
RemainAfterExit=no

[Install]
WantedBy=multi-user.target
```

- 🌞 **Tester le bon fonctionnement**
`[gaetan@backup system]$ sudo systemctl daemon-reload`
`[gaetan@backup system]$ sudo systemctl start tp2_backup.service`
```
[gaetan@backup system]$ sudo systemctl status tp2_backup.service
[...]
Oct 13 19:35:39 backup.tp2.linux tp2_backup.sh[3050]: [OK] Archive //tp2_backup_211013_193539.tar.gz created.
Oct 13 19:35:39 backup.tp2.linux tp2_backup.sh[3050]: [OK] Archive //tp2_backup_211013_193539.tar.gz synchronized to /srv/backup/web.tp>
Oct 13 19:35:39 backup.tp2.linux tp2_backup.sh[3050]: [OK] Directory /srv/backup/web.tp2.linux/ cleaned to keep only the 5 most recent >
Oct 13 19:35:39 backup.tp2.linux systemd[1]: tp2_backup.service: Succeeded.
Oct 13 19:35:39 backup.tp2.linux systemd[1]: Started Script Backup et compression.
```
```
[gaetan@backup web.tp2.linux]$ ls
tp2_backup_211013_190036.tar.gz  tp2_backup_211013_193539.tar.gz
```
### B. Timer

Un *timer systemd* permet l'exécution d'un *service* à intervalles réguliers.

- 🌞 **Créer le *timer* associé à notre `tp2_backup.service`**

`sudo touch tp2_backup.timer`
```
[gaetan@backup system]$ sudo systemctl start tp2_backup.timer
[gaetan@backup system]$ sudo systemctl enable tp2_backup.timer
Created symlink /etc/systemd/system/timers.target.wants/tp2_backup.timer → /etc/systemd/system/tp2_backup.timer.
```
```
[gaetan@backup system]$ sudo systemctl status tp2_backup.timer
● tp2_backup.timer - Periodically run our TP2 backup script
   Loaded: loaded (/etc/systemd/system/tp2_backup.timer; enabled; vendor preset: disabled)
   Active: active (running) since Wed 2021-10-13 19:45:38 CEST; 1min 2s ago
  Trigger: n/a

Oct 13 19:45:38 backup.tp2.linux systemd[1]: Started Periodically run our TP2 backup script.
```
- qu'il est paramétré pour être actif dès que le système boot
`Started Periodically run our TP2 backup script.`

- 🌞 **Tests !**
```
[gaetan@backup web.tp2.linux]$ ls
tp2_backup_211013_193539.tar.gz  tp2_backup_211013_194641.tar.gz  tp2_backup_211013_194843.tar.gz
tp2_backup_211013_194538.tar.gz  tp2_backup_211013_194743.tar.g
```

### C. Contexte

- 🌞 **Faites en sorte que...**


```
[gaetan@web system]$ sudo systemctl list-timers
NEXT                          LEFT     LAST                          PASSED  UNIT                         ACTIVATES
Fri 2021-10-15 03:15:00 CEST  13h left n/a                           n/a     tp2_backup.timer             tp2_backup.service
```

📁 **Fichier `/etc/systemd/system/tp2_backup.timer`**  
📁 **Fichier `/etc/systemd/system/tp2_backup.service`**

## 5. Backup de base de données

Sauvegarder des dossiers c'est bien. Mais sauvegarder aussi les bases de données c'est mieux.

- 🌞 **Création d'un script `/srv/tp2_backup_db.sh`**

