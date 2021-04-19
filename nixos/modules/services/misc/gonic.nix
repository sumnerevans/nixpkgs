{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.services.gonic;
in
{
  meta.maintainers = with maintainers; [ sumnerevans ];

  options = {

    services.gonic = {
      enable = mkEnableOption "music streaming server / subsonic server API implementation";

      user = mkOption {
        type = types.str;
        default = "gonic";
        description = "User account under which gonic runs.";
      };

      home = mkOption {
        type = types.path;
        default = "/var/lib/gonic";
        description = ''
          The directory where Gonic will create files. Make sure it is writable.
        '';
      };

      virtualHost = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = ''
          Name of the nginx virtualhost to use and setup. If null, do not setup
          any virtualhost.
        '';
      };

      listenAddress = mkOption {
        type = types.str;
        default = "0.0.0.0";
        description = ''
          The host name or IP address on which to bind Gonic. Only relevant if
          you have multiple network interfaces and want to make Gonic available
          on only one of them. The default value will bind Gonic to all
          available network interfaces.
        '';
      };

      port = mkOption {
        type = types.int;
        default = 4747;
        description = ''
          The port on which Gonic will listen for incoming HTTP traffic. Set to
          0 to disable.
        '';
      };

      musicPath = mkOption {
        type = types.path;
        description = ''
          The path to your music collection.
        '';
      };

      podcastPath = mkOption {
        type = types.path;
        description = ''
          The path to a podcasts directory.
        '';
      };

      cachePath = mkOption {
        type = types.path;
        default = "/var/lib/gonic/cache";
        description = ''
          The path to store audio transcodes, covers, etc.
        '';
      };

      dbPath = mkOption {
        type = types.path;
        default = "/var/lib/gonic/gonic.db";
        description = ''
          The path to the SQLite database.
        '';
      };

      proxyPrefix = mkOption {
        type = types.path;
        default = "/";
        example = "/gonic";
        description = ''
          The URL path prefix to use if behind reverse proxy.
        '';
      };

      scanInterval = mkOption {
        type = types.nullOr types.int;
        default = null;
        description = ''
          The interval (in minutes) to check for new music. If not set,
        '';
      };

      jukeboxEnabled = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether the Subsonic jukebox api should be enabled
        '';
      };

      genreSplit = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = ";";
        description = ''
          A string or character to split genre tags on for multi-genre support.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    systemd.services.gonic = {
      description = "Gonic Media Server";
      after = [ "network.target" ];
      wantedBy = [ "multi-user.target" ];

      preStart = ''
        mkdir -p ${cfg.cachePath}
      '';
      environment = {
        GONIC_MUSIC_PATH = cfg.musicPath;
        GONIC_PODCAST_PATH = cfg.podcastPath;
        GONIC_CACHE_PATH = cfg.cachePath;
        GONIC_DB_PATH = cfg.dbPath;
        GONIC_LISTEN_ADDR = "${cfg.listenAddress}:${toString cfg.port}";
        GONIC_PROXY_PREFIX = cfg.proxyPrefix;
      } // optionalAttrs cfg.jukeboxEnabled {
        GONIC_JUKEBOX_ENABLED = "1";
      } // optionalAttrs (cfg.scanInterval != null) {
        GONIC_SCAN_INTERVAL = toString cfg.scanInterval;
      } // optionalAttrs (cfg.genreSplit != null) {
        GONIC_GENRE_SPLIT = cfg.genreSplit;
      };
      serviceConfig = {
        ExecStart = "${pkgs.gonic}/bin/gonic";
        Restart = "always";
        User = "gonic";
        UMask = "0022";
      };
    };

    services.nginx = mkIf (cfg.virtualHost != null) {
      enable = true;
      recommendedProxySettings = true;
      virtualHosts.${cfg.virtualHost} = {
        locations.${cfg.proxyPrefix}.proxyPass = "http://${cfg.listenAddress}:${toString cfg.port}";
      };
    };

    users.users.gonic = {
      description = "Gonic service user";
      name = cfg.user;
      home = cfg.home;
      createHome = true;
      isSystemUser = true;
    };
  };
}
