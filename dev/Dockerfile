# Ambiente de teste do Lucerna: Arch + Hyprland + Quickshell.
# O Hyprland roda aninhado, como uma janela na sessão Wayland do host.
FROM archlinux:latest

RUN pacman -Syu --noconfirm --needed \
        hyprland quickshell \
        qt6-svg qt6-imageformats qt6-5compat \
        mesa vulkan-intel \
        dbus kitty grim wl-clipboard libnotify \
        ttf-jetbrains-mono-nerd noto-fonts noto-fonts-emoji \
    && pacman -Scc --noconfirm

ARG UID=1000
ARG GID=1000
RUN groupadd -g "$GID" dev \
    && useradd -m -u "$UID" -g "$GID" -s /bin/bash dev \
    && install -d -m 0700 -o "$UID" -g "$GID" "/run/user/$UID" \
    && install -d -o "$UID" -g "$GID" /home/dev/.config/quickshell /home/dev/.config/hypr

USER dev
ENV XDG_RUNTIME_DIR=/run/user/1000 \
    XDG_SESSION_TYPE=wayland \
    QT_QPA_PLATFORM=wayland
WORKDIR /home/dev

CMD ["dbus-run-session", "start-hyprland"]
