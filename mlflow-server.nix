{
  # special NixOps config
  network = {
    description = "MLflow server";
    enableRollback = true;
  };
  # end special NixOps config

  # from https://gist.github.com/nh2/28bce850755cf14bd7749ea78e4238ab
  /* boot.kernelModules = [ "tcp_bbr" ]; # faster tcp kernel support
  # Enable BBR congestion control
  boot.kernel.sysctl."net.ipv4.tcp_congestion_control" = "bbr"; */

  mlflow-server = { config, pkgs, ... }: let
    server_config = import ./secrets/server_config.nix;
  in {
    networking.firewall.enable = true;
    # Reject instead of drop.
    networking.firewall.rejectPackets = true;
    networking.firewall.allowedTCPPorts = [
      22
      80 # nginx
      443 # nginx
    ];

    environment.etc."boto.cfg" = {
      source = ./secrets/boto.cfg;
    };

    environment.systemPackages = with pkgs; [
        libmysqlclient
        mlflow-server
        mysql-client
      ];

    services.fail2ban.enable = true;

    services.nginx = {
      enable = true;
      virtualHosts = {
        "${server_config.hostname}" = {
          locations."/".proxyPass = "http://0.0.0.0:5000/";
          default = true;
          basicAuth = import ./secrets/basicauth.nix;
          forceSSL = true;
          enableACME = true;
        };
      };
    };

    security.acme = {
      email = "mlflow@tylerbenster.com";
      acceptTerms = true;
    };

    systemd.services.mlflowServer = {
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      description = "Start the mlflow server.";
      serviceConfig = {
        Type = "exec";
        Restart = "on-failure";
        RestartSec = "30";
        StandardOutput = "/var/log/mlflow-stdout.log";
        StandardError = "/var/log/mlflow-stderr.log";
        ExecStart = ''${pkgs.mlflow-server}/bin/mlflow server --backend-store-uri ${server_config.store_uri} --default-artifact-root ${server_config.artifact_root} --host 0.0.0.0'';
      };
    };

  };
}
