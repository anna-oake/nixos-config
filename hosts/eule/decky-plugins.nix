{
  inputs,
  config,
  pkgs,
  ...
}:
{
  imports = [
    inputs.decky-plugins.nixosModules.default
  ];

  jovian.decky-loader.plugins = with pkgs.decky-plugins; [
    audio_loader
    protondb_badges
  ];

  # Includes the fix for Steam's renamed initialization API (Decky PR #947).
  jovian.decky-loader.package = pkgs.decky-loader-prerelease;

  systemd.tmpfiles.settings."10-audio-loader-packs" = {
    "${config.jovian.decky-loader.stateDir}/sounds".d = {
      mode = "0755";
      user = "gamer";
      group = "users";
    };
    "${config.jovian.decky-loader.stateDir}/sounds/signalis"."L+" = {
      argument = toString (
        pkgs.fetchzip {
          url = "https://api.deckthemes.com/blobs/9b4cd368-8ba0-4248-8199-7bf817d794fe.zip";
          hash = "sha256-Y3c38TI23cqFBp8bAaYjuJHd0KoFk3u9wzwfMieQ43o=";
          derivationArgs.unpackCmd = ''
            unzip "$curSrc"
            chmod -R u+rwX .
          '';
        }
      );
    };
  };
}
