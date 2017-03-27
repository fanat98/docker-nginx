#!/bin/bash

#
# user id / group id
#

USERID=${USERID:-33}
USER=${USER:-www-data}
GROUPID=${GROUPID:-33}
GROUP=${GROUP:-www-data}

usermod -l ${USER} www-data
usermod -u ${USERID} -o ${USER}
groupmod -n ${GROUP} www-data
groupmod -g ${GROUPID} -o ${GROUP}

sed -i "s/^user\ .*/user\ \ ${USER};/" /etc/nginx/nginx.conf


#
# Log
#

mkdir -p /data/log/nginx
chown ${USER}:${GROUP} /data/log/nginx


case ${PHPFPM_ENV_APPLICATION_TYPE} in
	LARAVEL)
		DOCUMENT_ROOT=/data/web/releases/current/public/
		DOCUMENT_INDEX=index.php
	;;
	PHP)
		DOCUMENT_ROOT=/data/web/releases/current/
		DOCUMENT_INDEX=index.php
		;;
	TYPO3_7|TYPO3_8|YII2)
		DOCUMENT_ROOT=/data/web/releases/current/web/
		DOCUMENT_INDEX=index.php
		;;
	FLOW|FLOW_3|NEOS|NEOS_2)
		DOCUMENT_ROOT=/data/web/releases/current/Web/
		DOCUMENT_INDEX=index.php
		;;
	HTML)
		DOCUMENT_ROOT=/data/web/releases/current/
		DOCUMENT_INDEX=index.html
		;;
	*)
		echo "APPLICATION_TYPE '${APPLICATION_TYPE}' not supported."
		exit 1
esac


###################
# vhost
###################

rm -f -- /etc/nginx/conf.d/*.conf
if [ -e /opt/docker/nginx/vhost_${PHPFPM_ENV_APPLICATION_TYPE}.conf ]; then
	cp /opt/docker/nginx/vhost_${PHPFPM_ENV_APPLICATION_TYPE}.conf /etc/nginx/conf.d/vhost.conf
else
	cp /opt/docker/nginx/vhost.conf /etc/nginx/conf.d/vhost.conf
fi
/bin/sed -i "s@<DOCUMENT_ROOT>@${DOCUMENT_ROOT}@"         /etc/nginx/conf.d/vhost.conf
/bin/sed -i "s@<DOCUMENT_INDEX>@${DOCUMENT_INDEX}@"       /etc/nginx/conf.d/vhost.conf
/bin/sed -i "s@<TYPO3_CONTEXT>@${PHPFPM_ENV_TYPO3_CONTEXT}@"         /etc/nginx/conf.d/vhost.conf
/bin/sed -i "s@<FLOW_CONTEXT>@${PHPFPM_ENV_FLOW_CONTEXT}@"           /etc/nginx/conf.d/vhost.conf
/bin/sed -i "s@<FPM_HOST>@phpfpm@"    /etc/nginx/conf.d/vhost.conf
/bin/sed -i "s@<FPM_PORT>@${PHPFPM_PORT_9000_TCP_PORT}@"    /etc/nginx/conf.d/vhost.conf


mkdir -p ${DOCUMENT_ROOT}

#############################
## COMMAND
#############################

if [ "$1" = 'nginx' ]; then
	exec nginx -g "daemon off;"
fi

exec "$@"