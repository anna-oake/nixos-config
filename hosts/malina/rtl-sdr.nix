{
  services.rtl-tcp = {
    enable = true;
    biasTee = true;
  };

  services.rtl-proxy = {
    enable = true;

    frequencyOffsetHertz = 50000;

    clients = {
      satdump = {
        listen = "0.0.0.0:13000";
        priority = 0;
      };
      openwebrx = {
        listen = "0.0.0.0:13100";
        priority = 100;
      };
    };
  };
}
