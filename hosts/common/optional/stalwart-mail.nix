{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.stalwart-mail;
in
{
  # Stalwart admin password secret
  age.secrets.stalwart-admin-password = {
    file = ../../../secrets/stalwart-admin-password.age;
    owner = "root";
    mode = "0400";
  };

  services.stalwart-mail = {
    enable = true;
    package = pkgs.stalwart-mail;
    openFirewall = true;

    # Pass the admin password as a systemd credential
    credentials = {
      admin_password = config.age.secrets.stalwart-admin-password.path;
    };

    settings = {
      # Fallback admin account using credential
      authentication.fallback-admin = {
        user = "admin";
        secret = "%{file:/run/credentials/stalwart-mail.service/admin_password}%";
      };
      # Server configuration
      server = {
        hostname = config.networking.hostName;
        tls = {
          enable = true;
          implicit = true;
        };
        listener = {
          # SMTP for mail delivery (port 25)
          smtp = {
            protocol = "smtp";
            bind = [ "[::]:25" ];
          };
          # SMTP Submission with TLS (port 465)
          submissions = {
            protocol = "smtp";
            bind = [ "[::]:465" ];
            tls.implicit = true;
          };
          # SMTP Submission (port 587)
          submission = {
            protocol = "smtp";
            bind = [ "[::]:587" ];
          };
          # IMAPS (port 993)
          imaps = {
            protocol = "imap";
            bind = [ "[::]:993" ];
            tls.implicit = true;
          };
          # JMAP/Management interface (localhost only)
          jmap = {
            protocol = "http";
            bind = [ "127.0.0.1:8080" ];
          };
        };
      };

      # Storage configuration - use RocksDB for persistence
      store = {
        db = {
          type = "rocksdb";
          path = "/var/lib/stalwart-mail/data";
        };
        blob = {
          type = "rocksdb";
          path = "/var/lib/stalwart-mail/blob";
        };
      };
      storage = {
        data = "db";
        blob = "blob";
        fts = "db";
        lookup = "db";
        directory = "db";
      };

      # Directory for user authentication
      directory = {
        internal = {
          type = "internal";
          store = "db";
        };
      };

      # Session configuration
      session = {
        rcpt = {
          directory = "'internal'";
        };
        auth = {
          directory = "'internal'";
          mechanisms = [
            "PLAIN"
            "LOGIN"
          ];
        };
      };

      # Queue configuration - route all mail locally
      # (next-hop deprecated in v0.13.0, replaced by queue.strategy.route)
      queue.strategy.route = "local";

      # Resolver configuration
      resolver = {
        type = "system";
      };

      # Tracing/logging
      tracer = {
        stdout = {
          type = "stdout";
          level = "info";
          ansi = false;
          enable = true;
        };
      };
    };
  };

  # Firewall configuration for mail ports
  networking.firewall = {
    allowedTCPPorts = [
      25 # SMTP
      465 # SMTPS (Submission over TLS)
      587 # Submission
      993 # IMAPS
    ];
  };
}
