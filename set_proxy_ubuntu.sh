#! /bin/sh
# A script to set system-wide proxy in Ubuntu / Debian

if [ `id -u` -ne 0 ]
   then echo "Error: needs to be run as sudo!!"
   exit 1
fi

for i in "$@"
do
case $i in
    --unset)
    gsettings set org.gnome.system.proxy mode none
    truncate -s 0 /etc/profile.d/proxy.sh
    sed -i.bak "/Acquire::/d" /etc/apt/apt.conf
    sed -i.bak "/Acquire::/,+10d" /etc/apt/apt.conf.d/70debconf
    sed -i -e "s/${http_proxy}//g" /etc/environment
    if hash git 2>/dev/null; then
	git config --global --unset http.proxy
    fi
    exit 0
    ;;
    *)
    echo "Invalid option"
    exit 0
    ;;
esac
done

echo "Proxy Host:"; read PROXY_HOST
echo "Proxy Port:"; read PROXY_PORT


# setting system wide proxy
gsettings set org.gnome.system.proxy mode manual
gsettings set org.gnome.system.proxy.http host "$PROXY_HOST"
gsettings set org.gnome.system.proxy.http port "$PROXY_PORT"
gsettings set org.gnome.system.proxy.https host "$PROXY_HOST"
gsettings set org.gnome.system.proxy.https port "$PROXY_PORT"
gsettings set org.gnome.system.proxy.ftp host "$PROXY_HOST"
gsettings set org.gnome.system.proxy.ftp port "$PROXY_PORT"
gsettings set org.gnome.system.proxy.socks host "$PROXY_HOST"
gsettings set org.gnome.system.proxy.socks port "$PROXY_PORT"


# setting apt proxy
## in apt.conf
sed -i.bak '/http[s]::proxy/Id' /etc/apt/apt.conf
tee -a /etc/apt/apt.conf <<EOF
Acquire::http::proxy "http://${PROXY_HOST}:${PROXY_PORT}";
Acquire::https::proxy "http://${PROXY_HOST}:${PROXY_PORT}";
Acquire::ftp::Proxy "http://${PROXY_HOST}:${PROXY_PORT}";
EOF

## in apt.conf.d/70debconf
sed -i.bak '/http[s]::proxy/Id' /etc/apt/apt.conf.d/70debconf
tee -a /etc/apt/apt.conf.d/70debconf <<EOF
Acquire::http::proxy "http://${PROXY_HOST}:${PROXY_PORT}";
Acquire::https::proxy "http://${PROXY_HOST}:${PROXY_PORT}";
Acquire::ftp
 {
   Proxy "ftp://${PROXY_HOST}:{PROXY_PORT}";
   ProxyLogin 
   {
      "USER $(SITE_USER)@$(SITE)";
      "PASS $(SITE_PASS)";
   }
 }
EOF


# setting environment proxy
sed -i.bak '/http[s]_proxy/Id' /etc/environment
tee -a /etc/environment <<EOF
http_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
https_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
ftp_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
HTTP_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
HTTPS_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
FTP_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
no_proxy=127.0.0.0/8,::1,10.0.0.0/8
EOF

# proxy for profile
touch /etc/profile.d/proxy.sh
tee -a /etc/profile.d/proxy.sh <<EOF
export http_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
export https_proxy="http://${PROXY_HOST}:${PROXY_PORT}"
export HTTP_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
export HTTPS_PROXY="http://${PROXY_HOST}:${PROXY_PORT}"
EOF

# application specific proxy
# git
if hash git 2>/dev/null; then
	git config --global http.proxy "http://${PROXY_HOST}:${PROXY_PORT}"
fi
