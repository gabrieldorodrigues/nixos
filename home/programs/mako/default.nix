{ ... }:
{
  # mako (daemon de notificações; iniciado no autostart do Hyprland).
  # Estilo alinhado ao resto do sistema: paleta Catppuccin Mocha (mesma da
  # waybar/walker/kitty), JetBrainsMono Nerd Font, cantos arredondados e a
  # linguagem monocromática da barra (foreground num alpha baixo). Urgência
  # crítica ganha a borda vermelha #f38ba8. default-timeout é em ms.
  xdg.configFile."mako/config".text = ''
    # Layout e posição
    sort=-time
    layer=overlay
    anchor=top-right
    max-visible=5
    outer-margin=48,12,12,12
    margin=10

    # Dimensões e forma
    width=380
    height=140
    padding=14
    border-size=2
    border-radius=14
    icon-location=left
    max-icon-size=48

    # Tipografia
    font=JetBrainsMono Nerd Font 10
    markup=1
    actions=1
    format=<b>%s</b>\n%b

    # Cores (Catppuccin Mocha; foreground em alpha baixo, como a waybar)
    background-color=#1e1e2e
    text-color=#cdd6f4
    border-color=#cdd6f433
    progress-color=over #cba6f733

    # Tempo de exibição
    default-timeout=10000
    ignore-timeout=0

    [urgency=low]
    border-color=#cdd6f420
    text-color=#a6adc8
    default-timeout=5000

    [urgency=normal]
    border-color=#cdd6f433

    [urgency=critical]
    border-color=#f38ba8
    text-color=#cdd6f4
    default-timeout=0

    [mode=do-not-disturb]
    invisible=1
  '';
}
