#!/bin/bash
# Simple backup script
# gaetan ~ 12/10/21

# Colors
N="\e[0m"
B="\e[1m"
G="\e[32m"
R="\e[31m"
Y="\e[33m"

# Usage
usage() {
    programname=$0
    echo -e "${Y}${B}usage:${N} $programname [-k quantity] destination dir_to_backup"
    echo "  destination       Path to the directory that stores backups"
    echo "  dir_to_backup     Path to a directory to backup"
    echo "  -k quantity       Quantity of backups to keep (only most recent) in destination dir"
    exit 1
}

# Options handling
while getopts "hk:" OPTION; do
    case $OPTION in
        h)
            usage
            ;;
	k)
            qty_to_keep=$OPTARG
	    if ! [[ "$qty_to_keep" =~ ^[0-9]+$ ]] ;  then
              echo -e "${R}${B}[ERROR]${N} Argument for -k must be an integer."
	      exit 1
            fi

	    ;;
        *)
            usage
            ;;
    esac
done
shift $((OPTIND-1))

if [[ -z $1 || -z $2 ]] ; then
  >&2 echo -e "${R}${B}[ERROR]${N} You must specify a destination and a dir_to_backup." 
  >&2 echo
  usage
fi

# Global vars
destination=$1
target=$2
backup_name=$(date +tp2_backup_%y%m%d_%H%M%S.tar.gz)
backup_fullpath="$(pwd)/${backup_name}"

# Checks that must be ran before creatin the backup
preflight_checks() {
  if [[ $(id -u) -ne 0 ]] ; then
    >&2 echo -e "${R}${B}[ERROR]${N} This script must be run as root."
    exit 1
  fi

  if ! command -v rsync &> /dev/null ; then
    >&2 echo -e "${R}${B}[ERROR]${N} Command rsync not found."
    exit 1
  fi

  if [[ ! -d $destination ]] ; then
    >&2 echo -e "${R}${B}[ERROR]${N} Directory ${destination} is not accessible."
    exit 1
  fi

  if [[ ! -d $target && ! -f $target ]] ; then
    >&2 echo -e "${R}${B}[ERROR]${N} Target ${destination} is not accessible."
    exit 1
  fi
}

# Actually archive + compress $dir_to_archive
archive_and_compress() {
  dir_to_archive=$1
  tar cvzf "${backup_fullpath}" "${dir_to_archive}" &> /dev/null
  status=$?
  if [[ $status -eq 0 ]] ; then
    echo -e "${G}${B}[OK]${N} Archive ${backup_fullpath} created."
  else
    >&2 echo -e "${R}${B}[ERROR]${N} Creation of archive ${backup_fullpath} failed. (trying to archive ${dir_to_archive})"
    exit 1
  fi
}

# Synchronize $dir_to_archive into $destination dir
sync() {
  rsync -av --remove-source-files "${backup_fullpath}" "${destination}" &> /dev/null
  status=$?
  if [[ $status -eq 0 ]] ; then
    echo -e "${G}${B}[OK]${N} Archive ${backup_fullpath} synchronized to ${destination}."
  else
    >&2 echo -e "${R}${B}[ERROR]${N} Synchronization of ${backup_fullpath} to ${destination} failed."
    exit 1
  fi
}

# Takes an integer as argument : the maximum number of backups to keep in $destination dir
clean_backup() {
  # Keep 5 backups by default
  if [[ -z $qty_to_keep ]] ; then qty_to_keep=5 ; fi

  qty_to_keep_tail=$((qty_to_keep+1))
  ls -tp "${destination}" | grep -v '/$' | tail -n +${qty_to_keep_tail} | xargs -I {} rm -- ${destination}/{}
  status=$?
  if [[ $status -eq 0 ]] ; then
    echo -e "${G}${B}[OK]${N} Directory ${destination} cleaned to keep only the ${qty_to_keep} most recent backups."
  else
    >&2 echo -e "${R}${B}[ERROR]${N} Failed to clean ${destination}. Old backups may remain."
    exit 1
  fi
}

# Code
preflight_checks
archive_and_compress "${target}"
sync
clean_backup $qty_to_keep
