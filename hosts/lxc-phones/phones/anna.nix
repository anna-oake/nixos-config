{
  macAddress = "$MAC_ANNA";
  wallpaperFile = ../wallpapers/dunder-mifflin.png;

  sip = {
    phoneLabel = "Anna";
    buttons = [
      {
        button = 1;
        kind = "line";
        lineIndex = 1;
        port = 5160;
        name = "300";
        authName = "300";
        authPassword = "$SIP_PWD_ANNA";
        messagesNumber = "*97";
      }
      {
        button = 2;
        kind = "blf-speed-dial";
        label = "Maeve bedroom";
        speedDialNumber = "350";
      }
      {
        button = 3;
        kind = "blf-speed-dial";
        label = "macOS";
        speedDialNumber = "100";
      }
      {
        button = 4;
        kind = "blf-speed-dial";
        label = "Virtual";
        speedDialNumber = "301";
      }
    ];
  };
}
