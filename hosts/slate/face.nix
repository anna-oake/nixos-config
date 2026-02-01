{
  ...
}:
{
  security.polkit.enable = true;

  services.linux-enable-ir-emitter.enable = true;

  services.howdy = {
    enable = true;
    control = "sufficient";
    settings = {
      core.no_confirmation = true;
    };
  };

  disko.simple.impermanence.persist.directories = [
    "/var/lib/howdy/models"
  ];
}
