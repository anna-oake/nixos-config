{
  services.rtl-tcp = {
    enable = true;
    biasTee = true;
  };

  services.rtl-proxy = {
    enable = true;

    frequencyOffsetHertz = 250000;

    clients = {
      satdump = {
        listen = "0.0.0.0:13000";
        priority = 0;
      };
      openwebrx = {
        listen = "0.0.0.0:13100";
        priority = 100;
      };
      p2000 = {
        listen = "0.0.0.0:13900";
        priority = 900;
      };
    };
  };
}
