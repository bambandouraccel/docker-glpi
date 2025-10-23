FROM debian:12.5

LABEL org.opencontainers.image.authors="ndourbamba18@gmail.com"

ENV DEBIAN_FRONTEND=noninteractive \
    TIMEZONE=Africa/Dakar \
    VERSION_GLPI=11.0.0

# Installation des dépendances
RUN apt update \
 && apt install --yes ca-certificates apt-transport-https lsb-release wget curl gnupg2 \
 && curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg \
 && sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' \
 && apt update \
 && apt install --yes --no-install-recommends \
    apache2 \
    php8.3 \
    php8.3-mysql \
    php8.3-bcmath \
    php8.3-ldap \
    php8.3-xmlrpc \
    php8.3-imap \
    php8.3-curl \
    php8.3-gd \
    php8.3-mbstring \
    php8.3-xml \
    php8.3-intl \
    php8.3-zip \
    php8.3-bz2 \
    php8.3-redis \
    cron \
    jq \
    libldap-2.5-0 \
    libsasl2-2 \
    libsasl2-modules \
 && rm -rf /var/lib/apt/lists/*

# Télécharger et installer GLPI 11.0.0
RUN wget -q https://github.com/glpi-project/glpi/releases/download/11.0.0/glpi-11.0.0.tgz -O /tmp/glpi.tgz \
 && tar -xzf /tmp/glpi.tgz -C /var/www/html/ \
 && rm /tmp/glpi.tgz \
 && mv /var/www/html/glpi /var/www/html/glpi-original \
 && mkdir -p /var/www/html/glpi \
 && cp -r /var/www/html/glpi-original/* /var/www/html/glpi/ \
 && rm -rf /var/www/html/glpi-original

# Configuration Apache pour GLPI 11.0.0
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf \
 && echo "<VirtualHost *:8080>" > /etc/apache2/sites-available/000-default.conf \
 && echo "    DocumentRoot /var/www/html/glpi/public" >> /etc/apache2/sites-available/000-default.conf \
 && echo "    <Directory /var/www/html/glpi/public>" >> /etc/apache2/sites-available/000-default.conf \
 && echo "        Require all granted" >> /etc/apache2/sites-available/000-default.conf \
 && echo "        RewriteEngine On" >> /etc/apache2/sites-available/000-default.conf \
 && echo "        RewriteCond %{REQUEST_FILENAME} !-f" >> /etc/apache2/sites-available/000-default.conf \
 && echo "        RewriteRule ^(.*)$ index.php [QSA,L]" >> /etc/apache2/sites-available/000-default.conf \
 && echo "    </Directory>" >> /etc/apache2/sites-available/000-default.conf \
 && echo "    ErrorLog /var/log/apache2/error-glpi.log" >> /etc/apache2/sites-available/000-default.conf \
 && echo "    LogLevel warn" >> /etc/apache2/sites-available/000-default.conf \
 && echo "    CustomLog /var/log/apache2/access-glpi.log combined" >> /etc/apache2/sites-available/000-default.conf \
 && echo "</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf

# Configuration des permissions pour OpenShift
RUN chown -R 1001:0 /var/www/html /etc/apache2 /var/log/apache2 /var/run/apache2 \
 && chmod -R g+rwX /var/www/html /etc/apache2 /var/log/apache2 /var/run/apache2 \
 && a2enmod rewrite

# Script de démarrage adapté
COPY glpi-start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/glpi-start.sh

# Utilisateur OpenShift
USER 1001

EXPOSE 8080

CMD ["/usr/local/bin/glpi-start.sh"]
