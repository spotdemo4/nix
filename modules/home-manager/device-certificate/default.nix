{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkOption types;
  cfg = config.trev.programs.device-certificate;

  nickname = "trev-proxy device";
  key = config.age.secrets.device-certificate-key.path;

  # NSS databases of the browsers this home configures.
  databases =
    lib.optional (config.programs.chromium.enable or false) "${config.home.homeDirectory}/.pki/nssdb"
    ++ lib.optionals (config.programs.zen-browser.enable or false) (
      map (profile: "${config.programs.zen-browser.profilesPath}/${profile.path}") (
        lib.attrValues config.programs.zen-browser.profiles
      )
    );

  importCertificate = pkgs.writeShellApplication {
    name = "import-device-certificate";
    runtimeInputs = with pkgs; [
      nss.tools
      openssl
    ];
    text = ''
      bundle=$(mktemp -p "''${XDG_RUNTIME_DIR:-/tmp}")
      trap 'rm -f "$bundle"' EXIT
      openssl pkcs12 -export -name ${lib.escapeShellArg nickname} \
        -in ${cfg.certificate} -inkey ${lib.escapeShellArg key} -passout pass: -out "$bundle"

      for db in ${lib.escapeShellArgs databases}; do
        mkdir -p "$db"
        [ -e "$db/cert9.db" ] || certutil -N -d "sql:$db" --empty-password
        # Replace earlier copies, so a reissued certificate takes over.
        while certutil -F -d "sql:$db" -n ${lib.escapeShellArg nickname} 2>/dev/null; do :; done
        pk12util -i "$bundle" -d "sql:$db" -W ""
      done
    '';
  };
in
{
  options.trev.programs.device-certificate = {
    enable = lib.mkEnableOption "this device's trev-proxy client certificate";

    certificate = mkOption {
      type = types.path;
      description = "Client certificate the trev-proxy device CA issued to this device.";
    };

    key = mkOption {
      type = types.path;
      description = "Agenix-encrypted private key of the certificate.";
    };
  };

  config = lib.mkIf cfg.enable {
    age = {
      identityPaths = [ "${config.home.homeDirectory}/.ssh/id_ed25519" ];
      secrets.device-certificate-key = {
        file = cfg.key;
        path = "${config.xdg.configHome}/trev-proxy/device.key";
      };
    };

    # For clients outside the browsers, such as curl --cert.
    xdg.configFile."trev-proxy/device.pem".source = cfg.certificate;

    systemd.user.services.device-certificate = lib.mkIf (databases != [ ]) {
      Unit = {
        Description = "Import the trev-proxy device certificate into browser certificate databases";
        Wants = [ "agenix.service" ];
        After = [ "agenix.service" ];
      };
      Service = {
        Type = "oneshot";
        # Stay active so a changed certificate restarts the import on switch.
        RemainAfterExit = true;
        ExecStart = lib.getExe importCertificate;
      };
      Install.WantedBy = [ "default.target" ];
    };
  };
}
