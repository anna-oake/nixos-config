{
  macAddress = "3E945827FF05"; # it's an emulated raccoon so i'm comfortable with the MAC being public
  wallpaperFile = ../wallpapers/bliss.png;

  sip = {
    phoneLabel = "Virtual";
    buttons = [
      {
        button = 1;
        kind = "line";
        lineIndex = 1;
        port = 5160;
        name = "301";
        authName = "301";
        authPassword = "$SIP_PWD_VIRTUAL";
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
        label = "Raccoon";
        speedDialNumber = "300";
      }
    ];
  };
}
