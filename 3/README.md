# Création s'un serveur VPN

# Sommaire
- [Prérequis](#Prérequis)
- [Installation](#Installation)
- [Monitoring](#Monitoring)

----------------------------
**Prérequis**

- Une VM rocky Linux fonctionnel.
- iso rocky linux : https://rockylinux.org/download/

-----------------------------

## Installation de la VM : VPN :

**On commence par mettre à jour et installer les paquets que l'on souhaite, ainsi qu'une petite gestion de règles**

```
- sudo dnf update -y
- sudo dnf install epel-release -y
- sudo dnf install elrepo-release -y
- sudo dnf install kmod-wireguard wireguard-tools -y
- sudo firewall-cmd --remove-service dhcpv6-client --permanent
- sudo firewall-cmd --remove-service cockpit --permanent
- sudo firewall-cmd --reload
```
 **Configuration de wireguard (génération d'une paire de clé ssh)** : 
```
- sudo umask 077 | wg genkey | sudo tee /etc/wireguard/wireguard.key
- sudo wg pubkey < /etc/wireguard/wireguard.key | sudo tee /etc/wireguard/wireguard
- sudo vi /etc/wireguard/wg0.conf
```
 **Le fichier de conf doit être modifier comme ci dessous :** 
```
[Interface]
Address = [ip de votre VPN]
SaveConfig = true
ListenPort = 51820
DNS        = 8.8.8.8,1.1.1.1
PrivateKey = [votre clé privé]
PostUp = firewall-cmd --add-port=51820/udp; firewall-cmd --zone=public --add-masquerade; firewall-cmd --direct --add-rule ipv4 filter FORWARD 0 -i wg0 -o eth0 -j ACCEPT; firewall-cmd --direct --add-rule ipv4 nat POSTROUTING 0 -o eth0 -j MASQUERADE
PostDown = firewall-cmd --remove-port=51820/udp; firewall-cmd --zone=public --remove-masquerade; firewall-cmd --direct --remove-rule ipv4 filter FORWARD 0 -i wg0 -o eth0 -j ACCEPT; firewall-cmd --direct --remove-rule ipv4 nat POSTROUTING 0 -o eth0 -j MASQUERADE
```
**On active le transfert d'IP, et et recharge la conficuration 'systemctl' :** 

```
- echo "net.ipv4.ip_forward = 1" | sudo tee -a /etc/sysctl.conf
- sudo sysctl -p
```

**Puis dans un dernier temps on active la carte réseau de notre VPN :**

`- sudo systemctl start wg-quick@wg0`

---------------------------------------

**!! A faire après la création du client !!**

`- sudo wg set wg0 peer [clé public du client] allowed-ips [ip du client ]`

---------------------------------------

**!! A faire pour le montage NFS avec la backup !!**

**Installation du packet :**
`- sudo dnf -y install nfs-utils`

**Configuration du partage NFS**
```
sudo vi /etc/idmapd.conf
Domain = linux.tp3
sudo vi /etc/hosts
```
10.10.1.3 backup.linux.tp3

**On monte le partage :**
`- sudo mount -t nfs -o vers=3 [nom de votre backup]:/home/nfsshare /srv/backup/vpn/`

**Configuration pour monter par défaut**
```
sudo vi /etc/fstab 
backup.linux.tp3:/home/nfsshare /srv/backup/vpn        nfs defaults    0 0
```


---------------------------------------

## Installation de la VM : Client VPN :

**Pareil que la premiere VM, mise à jour et installation, ainsi qu'une petite gestion de règles**

```
- sudo dnf update -y
- sudo dnf install epel-release elrepo-release -y
- sudo dnf install kmod-wireguard wireguard-tools -y
- sudo firewall-cmd --remove-service dhcpv6-client --permanent
- sudo firewall-cmd --remove-service cockpit --permanent
- sudo firewall-cmd --reload
```

**Génération d'une paire de clé ssh :**
```
sudo su -
wg genkey | tee /etc/wireguard/privatekey | wg pubkey | tee /etc/wireguard/publickey
exit
```
 **Le fichier de conf doit être modifier comme ci dessous :**

`- sudo vi /etc/wireguard/wg0.conf`
```
[Interface]:
PrivateKey = [clé privé du client]
Address = [ip du client]

[Peer]
PublicKey = [clé public du VPN]
Endpoint = [ip du VPN]:51820
AllowedIPs = 0.0.0.0/0
```

**Puis dans un dernier temps on active la carte réseau de notre client VPN :**

`- sudo systemctl start wg-quick@wg0`


**Partage nfs coté VPN :**

**On installe les packets**
`sudo dnf -y install nfs-utils`

**Puis on configure le partage nfs coté VPN :**
```
sudo vi /etc/idmapd.conf
Domain = [votre nom de domain]

- sudo vi /etc/hosts
[ip de votre backup] nom de votre machine backup


sudo vi /etc/exports
/srv/backup [ip de votre vpn]/24(rw,no_root_squash)

mkdir /le_nom_de_votre_dossier_VPN

sudo mount -t nfs [nom de votre backup]:/le_nom_de_votre_dossier_BACKUP /le_nom_de_votre_dossier_VPN
sudo vi /etc/fstab 
[nom de votre backup]:/le_nom_de_votre_dossier_BACKUP /le_nom_de_votre_dossier_VPN        nfs defaults    0 0
```



-----------------------------------

## Installation de la VM : Backup :

**On commence par mettre à jour et installer les paquets que l'on souhaite, ainsi qu'une petite gestion de règles**
```
- sudo dnf update -y
- sudo dnf -y install nfs-utils
- sudo firewall-cmd --remove-service dhcpv6-client --permanent
- sudo firewall-cmd --remove-service cockpit --permanent
- sudo firewall-cmd --reload
```

**Pour le partage nfs :**


**On installe les packets**
`sudo dnf -y install nfs-utils`

**Puis on configure le partage nfs coté backup :**

```
sudo vi /etc/idmapd.conf 
Domain = [votre nom de domain]

sudo vi /etc/exports 
/srv/backup [ip de votre vpn]/24(rw,no_root_squash)


mkdir /le_nom_de_votre_dossier_BACKUP 
```
**Crétion d'une sauvegarde automatique sur la backup :**


```
sudo touch tp3_backup.sh
sudo vi tp3_backup.sh
https://gitlab.com/gaetan33460/b2_tp1_linux/-/blob/main/3/tp3_backup.sh

cd /etc/systemd/system/
sudo touch tp3_backup.service
sudo vi tp3_backup.service
https://gitlab.com/gaetan33460/b2_tp1_linux/-/blob/main/3/tp3_backup.service

sudo systemctl daemon-reload
sudo systemctl start tp3_backup.service


cd /etc/systemd/system/
sudo touch tp3_backup.timer
sudo vi tp3_backup.timer
https://gitlab.com/gaetan33460/b2_tp1_linux/-/blob/main/3/tp3_backup.timer
sudo systemctl start tp2_backup.timer
```


**Configuration du firewall :**
```
- sudo firewall-cmd --add-service=nfs
- sudo firewall-cmd --add-service={nfs3,mountd,rpc-bind} 
- sudo firewall-cmd --runtime-to-permanent 
- sudo firewall-cmd --reload
```

----------------------------------


## Monitoring avec netdata :

**!! NETDATA peut être installer sur n'importe quel machine que l'on souhaite surveiller !!**

**Installation de NETDATA :** 
```
- sudo su -
bash <(curl -Ss https://my-netdata.io/kickstart-static64.sh) -y
exit
```

**On démarre le service, et configure pour qu'il s'allume automatiquement**

```
- sudo systemctl start netdata.service
- sudo systemctl enable netdata.service
```

**On ajoute une règle au firewall**

```
- sudo firewall-cmd --add-port=19999/tcp --permanent
- sudo firewall-cmd --reload
```

**Configuration d'alerte avec un "BOT" DISCORD**

```
sudo /opt/netdata/etc/netdata/edit-config health_alarm_notify.conf
/DISCORD_WEBHOOK_URL
https://discord.com/api/webhooks/897105457062232074/OFaLJoOflWbYQqi1I4qeuG0U-GlPDVd_gpLJ7uElJNMoCXfh1x7GUt6a7OJWZQqZixCa
DEFAULT_RECIPIENT_DISCORD="alert-gaetan"
alert-gaetan
:wq
```
**On test le bon fonctionnement des alertes :**
```
su -s /bin/bash netdata
export NETDATA_ALARM_NOTIFY_DEBUG=1
/opt/netdata/usr/libexec/netdata/plugins.d/alarm-notify.sh test
sudo sed -i 's/curl=""/curl="\/opt\/netdata\/bin\/curl -k"/' /opt/netdata/etc/netdata/health_alarm_notify.conf
```

**On configure différents fichier pour gérer des alertes sur la ram, (il est possible de le faire sur le cpu aussi) :**
```
cd /opt/netdata/etc/netdata/
sudo ./edit-config health.d/ram.conf
/warn

warn: $this > (($status >= $WARNING)  ? (50) : (60))
crit: $this > (($status == $CRITICAL) ? (70) : (98))

```

**On test le bon fonctionnement de nos alarmes avec un stress test :**

```
sudo dnf install stress -y
sudo stress --vm 4 --vm-bytes 1024M
```

-----------------------------
