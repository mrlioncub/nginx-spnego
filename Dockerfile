FROM nginx:1.18.0-alpine

LABEL maintainer="mr.lioncub" \
      release-date="2020–05–08" \
      link1="https://github.com/stnoonan/spnego-http-auth-nginx-module"

RUN set -x \
  && tempDir="$(mktemp -d)" \
  && chown nobody:nobody $tempDir \
  && cd $tempDir \
  && wget "http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" \
  && tar xzf nginx-${NGINX_VERSION}.tar.gz \
  && apk add --no-cache krb5 \
  && apk add --no-cache --virtual .build-deps gcc libc-dev make openssl-dev pcre-dev zlib-dev linux-headers curl gnupg libxslt-dev gd-dev geoip-dev git krb5-dev \
  && git config --global http.proxy $http_proxy \
  && git clone https://github.com/stnoonan/spnego-http-auth-nginx-module.git nginx-${NGINX_VERSION}/spnego-http-auth-nginx-module \
  && CONFARGS=$(nginx -V 2>&1 | sed -n -e 's/^.*arguments: //p') \
  && CONFARGS=${CONFARGS/-Os -fomit-frame-pointer/-Os} \
  && cd nginx-$NGINX_VERSION \
  && ./configure --with-compat $CONFARGS --add-dynamic-module=spnego-http-auth-nginx-module \
  && make modules \
  && cp objs/ngx_http_auth_spnego_module.so /etc/nginx/modules/ \
  && sed -i -e '1 s/^/load_module \/etc\/nginx\/modules\/ngx_http_auth_spnego_module.so;\n/;' /etc/nginx/nginx.conf \
  && cd / \
  && rm -rf $tempDir \
  && apk del .build-deps \
  && rm -rf /var/cache/apk/* \
  && ln -sf /dev/stdout /var/log/nginx/access.log \
  && ln -sf /dev/stderr /var/log/nginx/error.log

EXPOSE 80

STOPSIGNAL SIGTERM

CMD ["nginx", "-g", "daemon off;"]