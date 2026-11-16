{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.nix-darwin;
  signing = cfg.signing;
  policyType = lib.types.submodule {
    options = {
      entitlements = lib.mkOption {
        type = lib.types.attrsOf (lib.types.attrsOf lib.types.anything);
        default = { };
        description = ''
          Entitlement overrides keyed by code path relative to an output. Values
          merge with existing entitlements. Use null to remove an entitlement.
          Bundle paths refer to the bundle itself, not its main executable.
        '';
      };
      removeEntitlements = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Entitlements to remove from every code item before signing.";
      };
    };
  };
  policies = lib.mapAttrs (_: settings: settings.policy) cfg.signedPackages;
  serviceConfig = pkgs.writeText "nix-developer-id.json" (
    builtins.toJSON {
      inherit (signing)
        identity
        teamId
        keychain
        passwordFile
        socketPath
        ;
      packages = policies;
    }
  );
  signOverlay =
    final: prev:
    let
      client = prev.writeShellScript "nix-developer-id-client" ''
        exec ${prev.python3}/bin/python3 ${./signing.py} client "$@"
      '';
    in
    lib.mapAttrs (
      name: settings:
      let
        original = prev.${name};
        request = prev.writeText "${name}-developer-id.json" (
          builtins.toJSON {
            package = name;
            inherit (signing) identity teamId;
            policy = settings.policy;
          }
        );
        signPhase = ''
          for outputName in $(getAllOutputNames); do
            outputPath="''${!outputName}"
            if [ -d "$outputPath" ]; then
              ${client} --socket ${lib.escapeShellArg signing.socketPath} \
                --request ${request} --output "$outputPath"
            fi
          done
        '';
        appendPhase =
          phases:
          if lib.isList phases then
            phases ++ [ "developerIdSignPhase" ]
          else
            "${phases} developerIdSignPhase";
      in
      original.overrideAttrs (
        old:
        assert lib.assertMsg (
          !(old ? buildCommandPath)
        ) "signedPackages.${name}: buildCommandPath builders are not supported";
        {
          # Re-sign after *all* normal phases, including packages with dontFixup.
          # Explicit phase lists bypass postPhases and need extending directly.
          postPhases = appendPhase (old.postPhases or [ ]);
          developerIdSignPhase = signPhase;
        }
        // lib.optionalAttrs (old ? phases) {
          phases = appendPhase old.phases;
        }
        // lib.optionalAttrs (old ? buildCommand) {
          buildCommand = old.buildCommand + "\n" + signPhase;
        }
      )
    ) cfg.signedPackages;
in
{
  options.nix-darwin = {
    signedPackages = lib.mkOption {
      default = { };
      type = lib.types.attrsOf (
        lib.types.submodule {
          options.policy = lib.mkOption {
            type = policyType;
            default = { };
            description = "Optional exceptions to automatic Developer ID signing.";
          };
        }
      );
      description = ''
        Package attributes to replace with Developer ID-signed builds. Original
        package expressions are unchanged. Signing failures fail the build.
      '';
    };
    signing = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = cfg.signedPackages != { };
        description = "Run the local Developer ID signing service.";
      };
      enablePackageSigning = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Apply the signing overlay. Temporarily disable for the initial
          activation that installs the service on a new builder.
        '';
      };
      identity = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "SHA-1 fingerprint of the Developer ID Application certificate.";
      };
      teamId = lib.mkOption {
        type = lib.types.str;
        default = "";
        description = "Expected Apple Developer Team ID, verified after signing.";
      };
      user = lib.mkOption {
        type = lib.types.str;
        default = config.system.primaryUser;
        description = "User owning the dedicated signing keychain and service.";
      };
      keychain = lib.mkOption {
        type = lib.types.str;
        default = "/Users/${signing.user}/Library/Keychains/nix-developer-id.keychain-db";
        description = "Host-local dedicated keychain; never imported into the Nix store.";
      };
      passwordFile = lib.mkOption {
        type = lib.types.str;
        default = "/Users/${signing.user}/.config/nix-developer-id/keychain-password";
        description = "Host-local file containing the signing keychain password.";
      };
      socketPath = lib.mkOption {
        type = lib.types.str;
        default = "/var/run/nix-developer-id/sign.sock";
        description = "Local Unix socket accessible to Nix build users.";
      };
    };
  };

  config = lib.mkIf signing.enable {
    assertions = [
      {
        assertion = builtins.match "[0-9A-Fa-f]{40}" signing.identity != null;
        message = "nix-darwin.signing.identity must be a Developer ID certificate SHA-1 fingerprint.";
      }
      {
        assertion = builtins.match "[A-Z0-9]{10}" signing.teamId != null;
        message = "nix-darwin.signing.teamId must be a 10-character Apple Team ID.";
      }
      {
        assertion =
          !(lib.hasPrefix "/nix/store/" signing.keychain)
          && !(lib.hasPrefix "/nix/store/" signing.passwordFile);
        message = "Developer ID keychains and passwords must be kept outside the Nix store.";
      }
    ];

    nixpkgs.overlays = lib.mkIf signing.enablePackageSigning (lib.mkAfter [ signOverlay ]);

    # The broker signs private staging copies, never paths supplied by builders.
    # Only the broker can access the dedicated keychain.
    launchd.daemons.nix-developer-id.serviceConfig = {
      ProgramArguments = [
        "${pkgs.python3}/bin/python3"
        "${./signing.py}"
        "serve"
        "--config"
        "${serviceConfig}"
      ];
      UserName = signing.user;
      GroupName = config.nix.settings.build-users-group or "nixbld";
      RunAtLoad = true;
      KeepAlive = true;
      ThrottleInterval = 5;
      ProcessType = "Background";
      StandardOutPath = "/var/log/nix-developer-id.log";
      StandardErrorPath = "/var/log/nix-developer-id.log";
    };

    system.activationScripts.preActivation.text = lib.mkAfter ''
      /usr/bin/install -d -m 0750 \
        -o ${lib.escapeShellArg signing.user} \
        -g ${lib.escapeShellArg (config.nix.settings.build-users-group or "nixbld")} \
        ${lib.escapeShellArg (builtins.dirOf signing.socketPath)}
      /usr/bin/touch /var/log/nix-developer-id.log
      /usr/sbin/chown ${lib.escapeShellArg signing.user} /var/log/nix-developer-id.log
      /bin/chmod 0600 /var/log/nix-developer-id.log
    '';
  };
}
