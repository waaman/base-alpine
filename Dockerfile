FROM alpine:3.16.0

ENV TZ="Europe/Paris"
ENV PUID="99"
ENV PGID="100"

###############################################################################################################
##### Paquets nécessaires + TZ + création dossier workdir
###############################################################################################################
RUN echo "${TZ}" > /etc/timezone \
    && mkdir /app \
    && chmod -R 0777 /app \
    && apk add --update --no-cache --virtual .build_deps tar xz

###############################################################################################################
##### s6-overlaye
###############################################################################################################
ARG S6_OVERLAY_VERSION="3.1.0.1"
ARG S6_OVERLAY_ARCH="x86_64"

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-${S6_OVERLAY_ARCH}.tar.xz

ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-symlinks-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-symlinks-arch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-symlinks-arch.tar.xz

# Ménage
RUN rm -rf /tmp/*
RUN apk del .build_deps


###############################################################################################################
##### Bash à la place de ash et paquets que l'on conserve
###############################################################################################################
RUN apk --no-cache add \
    nano \
    tree \
    bash \
    bash-doc \
    bash-completion \
    ncurses \
    sudo

###############################################################################################################
##### User alpine
###############################################################################################################
RUN adduser --disabled-password -h /app -u ${PUID} -G `getent group ${PGID} | cut -d: -f1` -s /bin/ash alpine
RUN passwd -d alpine
RUN echo 'alpine:123456' | chpasswd
RUN echo '%wheel ALL=(ALL) ALL' > /etc/sudoers.d/wheel
RUN adduser alpine wheel

USER alpine
RUN echo "exec /bin/bash" > ~/.profile
RUN echo "source /etc/profile.d/bash_completion.sh" > ~/.bashrc
RUN echo "alias dir='ls --color=never -alh'" >> ~/.bashrc
RUN echo "alias lsa='ls -alh'" >> ~/.bashrc
RUN echo "alias mkdir='mkdir --verbose'" >> ~/.bashrc    
RUN echo 'export PS1="\[\e[31m\][\[\e[m\]\[\e[38;5;172m\]\u\[\e[m\]@\[\e[38;5;153m\]\h\[\e[m\] \[\e[38;5;214m\]\W\[\e[m\]\[\e[31m\]]\[\e[m\]\$ "' >> ~/.bashrc   
RUN echo 'export EDITOR="nano"' >> ~/.bashrc

USER root
RUN echo "exec /bin/bash" > ~/.profile
RUN echo "source /etc/profile.d/bash_completion.sh" > ~/.bashrc
RUN echo "alias dir='ls --color=never -alh'" >> ~/.bashrc
RUN echo "alias lsa='ls -alh'" >> ~/.bashrc
RUN echo "alias mkdir='mkdir --verbose'" >> ~/.bashrc    
RUN echo 'export PS1="\[\e[31m\][\[\e[m\]\[\e[38;5;172m\]\u\[\e[m\]@\[\e[38;5;153m\]\h\[\e[m\] \[\e[38;5;214m\]\W\[\e[m\]\[\e[31m\]]\[\e[m\]\$ "' >> ~/.bashrc   
RUN echo 'export EDITOR="nano"' >> ~/.bashrc

RUN sed -e 's;/bin/ash$;/bin/bash;g' -i /etc/passwd

###############################################################################################################
##### Copie des fichiers de rootfs/ vers / du container
###############################################################################################################
COPY rootfs /

WORKDIR /app
VOLUME [ "/app" ]
ENTRYPOINT [ "/init" ]