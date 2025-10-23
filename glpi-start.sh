#!/bin/bash

# Configuration timezone
if [[ -n "${TIMEZONE}" ]]; then
    echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.3/apache2/conf.d/timezone.ini
    echo "date.timezone = \"$TIMEZONE\"" > /etc/php/8.3/cli/conf.d/timezone.ini
fi

# Enable session.cookie_httponly
sed -i 's/session.cookie_httponly =.*/session.cookie_httponly = on/' /etc/php/8.3/apache2/php.ini

# Configuration LDAP
if ! grep -q "TLS_REQCERT" /etc/ldap/ldap.conf; then
    echo "TLS_REQCERT never" >> /etc/ldap/ldap.conf
fi

# Vérification de l'installation GLPI
FOLDER_GLPI="glpi/"
FOLDER_WEB="/var/www/html/"

if [ ! "$(ls ${FOLDER_WEB}${FOLDER_GLPI}/bin)" ]; then
    echo "Installing GLPI..."
    SRC_GLPI=$(curl -s https://api.github.com/repos/glpi-project/glpi/releases/tags/11.0.0 | jq -r '.assets[0].browser_download_url')
    TAR_GLPI=$(basename ${SRC_GLPI})
    
    wget -P ${FOLDER_WEB} ${SRC_GLPI}
    tar -xzf ${FOLDER_WEB}${TAR_GLPI} -C ${FOLDER_WEB}
    rm -f ${FOLDER_WEB}${TAR_GLPI}
fi

# Configuration des permissions
chown -R 1001:0 ${FOLDER_WEB}${FOLDER_GLPI}
chmod -R g+rwX ${FOLDER_WEB}${FOLDER_GLPI}

# Configuration cron pour GLPI 11.0.0
echo "*/2 * * * * /usr/bin/php /var/www/html/glpi/front/cron.php &>/dev/null" > /etc/cron.d/glpi
chmod 0644 /etc/cron.d/glpi

# Démarrage des services
service cron start
a2enmod rewrite

# Lancement d'Apache
/usr/sbin/apache2ctl -D FOREGROUND
