FROM debian:12.5

LABEL org.opencontainers.image.authors="ndourbamba18@gmail.com"

ENV DEBIAN_FRONTEND=noninteractive \
    TIMEZONE=Africa/Dakar

# ==============================
# 1️⃣ Installation des dépendances système et PHP 8.3
# ==============================
RUN apt update \
 && apt install --yes ca-certificates apt-transport-https lsb-release wget curl git unzip \
 && curl -sSLo /usr/share/keyrings/deb.sury.org-php.gpg https://packages.sury.org/php/apt.gpg \
 && sh -c 'echo "deb [signed-by=/usr/share/keyrings/deb.sury.org-php.gpg] https://packages.sury.org/php/ $(lsb_release -sc) main" > /etc/apt/sources.list.d/php.list' \
 && apt update \
 && apt install --yes --no-install-recommends \
    apache2 \
    php8.3 \
    php8.3-cli \
    php8.3-mysql \
    php8.3-bcmath \
    php8.3-ldap \
    php8.3-xmlrpc \
    php8.3-imap \
    php8.3-curl \
    php8.3-gd \
    php8.3-mbstring \
    php8.3-xml \
    php-cas \
    php8.3-intl \
    php8.3-zip \
    php8.3-bz2 \
    php8.3-redis \
    cron \
    jq \
    composer \
    libldap-2.5-0 \
    libldap-common \
    libsasl2-2 \
    libsasl2-modules \
    libsasl2-modules-db \
 && rm -rf /var/lib/apt/lists/*

# ==============================
# 2️⃣ Clonage de GLPI depuis ton dépôt GitHub (branche glpi-v11.0.1)
# ==============================
RUN git clone --branch glpi-v11.0.1 --depth=1 https://github.com/bambandouraccel/glpi.git /var/www/html/glpi \
 && cd /var/www/html/glpi \
 && composer install --no-dev --optimize-autoloader --no-interaction \
 && chown -R 1001:0 /var/www/html/glpi


# ==============================
# 3️⃣ Configuration Apache pour GLPI
# ==============================
RUN sed -i 's/Listen 80/Listen 8080/' /etc/apache2/ports.conf \
 && echo "<VirtualHost *:8080>" > /etc/apache2/sites-available/000-default.conf \
 && echo "    DocumentRoot /var/www/html/glpi/public" >> /etc/apache2/sites-available/000-default.conf \
 && echo "    <Directory /var/www/html/glpi/public>" >> /etc/apache2/sites-available/000-default.conf \
 && echo "        Require all granted" >> /etc/apache2/sites-available/000-default.conf \
 && echo "        AllowOverride All" >> /etc/apache2/sites-available/000-default.conf \
 && echo "        Options FollowSymlinks" >> /etc/apache2/sites-available/000-default.conf \
 && echo "        RewriteEngine On" >> /etc/apache2/sites-available/000-default.conf \
 && echo "        RewriteCond %{REQUEST_FILENAME} !-f" >> /etc/apache2/sites-available/000-default.conf \
 && echo "        RewriteRule ^(.*)$ index.php [QSA,L]" >> /etc/apache2/sites-available/000-default.conf \
 && echo "    </Directory>" >> /etc/apache2/sites-available/000-default.conf \
 && echo "</VirtualHost>" >> /etc/apache2/sites-available/000-default.conf \
 && a2enmod rewrite \
 && chown -R 1001:0 /etc/apache2 /etc/php /var/log/apache2 /var/run/apache2 /var/www/html \
 && chmod -R g+rwX /var/www/html /etc/apache2 /etc/php /var/log/apache2 /var/run/apache2

# ==============================
# 4️⃣ Page d’accueil par défaut
# ==============================
RUN echo "<?php header('Location: /glpi/'); ?>" > /var/www/html/index.php

# ==============================
# 5️⃣ Tâches planifiées (cron GLPI)
# ==============================
RUN echo "*/2 * * * * www-data /usr/bin/php /var/www/html/glpi/front/cron.php &>/dev/null" > /etc/cron.d/glpi \
 && service cron start

# ==============================
# 6️⃣ Permissions et utilisateur OpenShift
# ==============================
USER 1001

EXPOSE 8080

# ==============================
# 7️⃣ Commande de démarrage
# ==============================
CMD ["apache2ctl", "-D", "FOREGROUND"]
