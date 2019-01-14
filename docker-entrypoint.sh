#!/bin/bash

# Read user names and passwords from the user file and turn them into users
# Lines should be of the format "username password", with each user on its own line.
user_file=/config/users
if [ -e "$user_file" ]; then
  while read -r line; do
      read user pass <<<"$line"
      echo "Adding user #{user} with pass ${pass}"
      adduser --no-create-home --disabled-password --gecos '' "${user}"
      echo "${user}:${pass}" | chpasswd
  done < "$user_file"
fi

if [ ! -z "${AFP_USER}" ]; then
    if [ ! -z "${AFP_UID}" ]; then
        cmd="$cmd --uid ${AFP_UID}"
    fi
    if [ ! -z "${AFP_GID}" ]; then
        cmd="$cmd --gid ${AFP_GID}"
        groupadd --gid ${AFP_GID} ${AFP_USER}
    fi
    adduser $cmd --no-create-home --disabled-password --gecos '' "${AFP_USER}"
    if [ ! -z "${AFP_PASSWORD}" ]; then
        echo "${AFP_USER}:${AFP_PASSWORD}" | chpasswd
    fi
fi

if [ ! -d /media/share ]; then
  mkdir /media/share
  echo "use -v /my/dir/to/share:/media/share" > readme.txt
fi
chown "${AFP_USER}" /media/share

if [ ! -d /media/timemachine ]; then
  mkdir /media/timemachine
  echo "use -v /my/dir/to/timemachine:/media/timemachine" > readme.txt
fi
chown "${AFP_USER}" /media/timemachine

sed -i'' -e "s,%USER%,${AFP_USER:-},g" /etc/afp.conf

echo ---begin-afp.conf--
cat /etc/afp.conf
echo ---end---afp.conf--

mkdir -p /var/run/dbus
rm -f /var/run/dbus/pid
dbus-daemon --system

exec netatalk -d
