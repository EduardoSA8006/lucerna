# Ambiente de teste do Lucerna: Arch + Hyprland + Quickshell.
# O Hyprland roda aninhado, como uma janela na sessão Wayland do host.
FROM archlinux:latest

# mpv e mpv-mpris só servem para testar a aba Mídia (um player MPRIS). O ffmpeg
# e o Qt Multimedia (com o driver VA-API da Intel) são dos wallpapers em vídeo.
RUN pacman -Syu --noconfirm --needed \
        hyprland quickshell \
        qt6-svg qt6-imageformats qt6-5compat \
        mesa vulkan-intel \
        qt6-multimedia qt6-multimedia-ffmpeg intel-media-driver libva-utils \
        dbus kitty foot htop grim wl-clipboard libnotify wtype \
        wireplumber brightnessctl \
        ttf-material-symbols-variable ttf-jetbrains-mono-nerd ttf-cascadia-code-nerd noto-fonts noto-fonts-emoji \
        mpv mpv-mpris ffmpeg \
        hicolor-icon-theme adwaita-icon-theme \
    && pacman -Scc --noconfirm

# Senha do usuário "dev" para testar a tela de bloqueio (PAM): lucerna
ARG UID=1000
ARG GID=1000
RUN groupadd -g "$GID" dev \
    && useradd -m -u "$UID" -g "$GID" -s /bin/bash dev \
    && echo 'dev:lucerna' | chpasswd \
    && install -d -m 0700 -o "$UID" -g "$GID" "/run/user/$UID" \
    && install -d -o "$UID" -g "$GID" /home/dev/.config/quickshell /home/dev/.config/hypr

USER dev
ENV USER=dev \
    XDG_RUNTIME_DIR=/run/user/1000 \
    XDG_SESSION_TYPE=wayland \
    QT_QPA_PLATFORM=wayland \
    LANG=pt_BR.UTF-8 \
    QS_ICON_THEME=Adwaita
WORKDIR /home/dev

CMD ["dbus-run-session", "start-hyprland"]
