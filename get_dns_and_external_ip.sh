dns=$(grep '^nameserver' /etc/resolv.conf | head -n 1 | awk '{print $2}')
#Le script ci-dessous n'a pas besoin de rouler toutes les 5 secondes, je l'ai mis dans un hourly systemd.timer
#external=$(curl -s --connect-timeout 5 http://ifconfig.me)
#
#Maintenant je prends le external ip à partir du log file qui est mis à jour par le systemd.timer get_external_ip.timer
external=$(cat /var/log/externalip.log)

echo "{\"text\": \"$dns\", \"tooltip\": \"External IP: $external\"}"
