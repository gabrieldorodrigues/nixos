# Sound configuration with PipeWire.
{ config, pkgs, ... }:

{
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;

    # High-quality audio: force 48 kHz (Elgato Wave 1 is 24-bit/48 kHz)
    # and improve resampler quality to avoid degradation.
    extraConfig.pipewire."99-highquality" = {
      "context.properties" = {
        "default.clock.rate" = 48000;
        "default.clock.allowed-rates" = [ 44100 48000 96000 ];
        # Lower quantum improves latency; keep a safe range.
        "default.clock.quantum" = 1024;
        "default.clock.min-quantum" = 256;
        "default.clock.max-quantum" = 2048;
      };
    };

    extraConfig.pipewire-pulse."99-highquality" = {
      "context.properties" = {
        "resample.quality" = 10;
      };
    };
  };

  # RNNoise noise suppression for the Elgato Wave 1.
  # Creates a virtual source "Wave1 NoiseReduced" that applies real-time
  # noise reduction. Select it as your input in Discord/OBS/etc.
  services.pipewire.extraConfig.pipewire."99-wave-rnnoise" = {
    "context.modules" = [
      {
        name = "libpipewire-module-filter-chain";
        args = {
          "node.description" = "Wave1 NoiseReduced";
          "media.name" = "Wave1 NoiseReduced";
          "filter.graph" = {
            nodes = [
              {
                type = "ladspa";
                name = "rnnoise";
                plugin = "${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so";
                label = "noise_suppressor_mono";
                control = {
                  "VAD Threshold (%)" = 50.0;
                  "VAD Grace Period (ms)" = 200;
                  "Retroactive VAD Grace (ms)" = 0;
                };
              }
            ];
          };
          "capture.props" = {
            "node.name" = "capture.rnnoise_source";
            "node.passive" = true;
            "audio.rate" = 48000;
            # Always capture from the Elgato Wave 1 hardware input.
            "target.object" = "alsa_input.usb-Elgato_Systems_Elgato_Wave_1_AS44J1A06773-00.mono-fallback";
          };
          "playback.props" = {
            "node.name" = "rnnoise_source";
            "media.class" = "Audio/Source";
            "audio.rate" = 48000;
          };
        };
      }
    ];
  };

  # WirePlumber: dedicated high-quality rule for the Elgato Wave 1 input.
  # Disables automatic resampling on the device node and uses a
  # high-quality resampler when needed.
  services.pipewire.wireplumber.extraConfig."99-elgato-wave" = {
    "monitor.alsa.rules" = [
      {
        matches = [
          { "node.name" = "~alsa_input.*Wave.*"; }
          { "device.name" = "~alsa_card.*Wave.*"; }
        ];
        actions.update-props = {
          "audio.rate" = 48000;
          "audio.allowed-rates" = [ 48000 ];
          "resample.quality" = 10;
          "session.suspend-timeout-seconds" = 0;
        };
      }
    ];
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;
}
