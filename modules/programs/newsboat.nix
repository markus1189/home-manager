{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.newsboat;
  wrapQuote = x: ''"${x}"'';
  toYesNo = b: if b then "yes" else "no";
in {
  meta.maintainers = [ maintainers.markus1189 ];

  options = {
    programs.newsboat = {
      enable = mkEnableOption "the Newsboat feed reader";

      urls = mkOption {
        type = types.listOf (types.submodule {
          options = {
            url = mkOption {
              type = types.str;
              example = "http://example.com";
              description = "Feed URL.";
            };

            tags = mkOption {
              type = types.listOf types.str;
              default = [ ];
              example = [ "foo" "bar" ];
              description = "Feed tags.";
            };

            title = mkOption {
              type = types.nullOr types.str;
              default = null;
              example = "ORF News";
              description = "Feed title.";
            };
          };
        });
        default = [ ];
        example = [{
          url = "http://example.com";
          tags = [ "foo" "bar" ];
        }];
        description = "List of news feeds.";
      };

      maxItems = mkOption {
        type = types.int;
        default = 0;
        description = "Maximum number of items per feed, 0 for infinite.";
      };

      reloadThreads = mkOption {
        type = types.int;
        default = 5;
        description = "How many threads to use for updating the feeds.";
      };

      autoReload = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Whether to enable automatic reloading while newsboat is running.
        '';
      };

      reloadTime = mkOption {
        type = types.nullOr types.int;
        default = 60;
        description = "Time in minutes between reloads.";
      };

      browser = mkOption {
        type = types.str;
        default = "${pkgs.xdg_utils}/bin/xdg-open";
        description = "External browser to use.";
      };

      queries = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = { "foo" = ''rssurl =~ "example.com"''; };
        description = "A list of queries to use.";
      };

      cleanupOnQuit = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If set to true, then the cache gets locked and superfluous
          feeds and items are removed, such as feeds that can’t be found
          in the urls configuration file anymore.
        '';
      };

      deleteReadArticlesOnQuit = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If set to true, then all read articles will be deleted when
          you quit newsboat.
        '';
      };

      showReadFeeds = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If set to true, then all feeds, including those without
          unread articles, are listed. If set to false, then only feeds
          with one or more unread articles are list.
        '';
      };

      showReadArticles = mkOption {
        type = types.bool;
        default = true;
        description = ''
          If set to true, then all articles of a feed are listed in the
          article list. If set to false, then only unread articles are
          listed.
        '';
      };

      confirmExit = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If set to true, then newsboat will ask for confirmation
          whether the user really wants to quit newsboat.
        '';
      };

      downloadFullPage = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If set to true, then for all feed items with no content but
          with a link, the link is downloaded and the result used as
          content instead. This may significantly increase the
          download times of "empty" feeds.
        '';
      };

      historyLimit = mkOption {
        type = types.int;
        default = 100;
        description = ''
          Defines the maximum number of entries of commandline
          resp. search history to be saved. To disable history saving,
          set it to 0.
        '';
      };

      bookmarkCmd = mkOption {
        type = types.nullOr types.str;
        default = null;
        example = "~/bin/my-bookmark-cmd.sh";
        description = ''
          If set, then this command will be used as bookmarking
          plugin. See the documentation on bookmarking for further
          information.
        '';
      };

      bookmarkInteractive = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If set to true, then the configured bookmark command is an
          interactive program.
        '';
      };

      bookmarkAutopilot = mkOption {
        type = types.bool;
        default = false;
        description = ''
          If set to true, the configured bookmark command is executed
          without any further input asked from user, unless the url or
          the title cannot be found/guessed.
        '';
      };

      extraConfig = mkOption {
        type = types.lines;
        default = "";
        description = ''
          Extra configuration values that will be appended to the end.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ pkgs.newsboat ];
    home.file.".newsboat/urls".text = let
      mkUrlEntry = u:
        concatStringsSep " " ([ u.url ] ++ map wrapQuote u.tags
          ++ optional (u.title != null) (wrapQuote "~${u.title}"));
      urls = map mkUrlEntry cfg.urls;

      mkQueryEntry = n: v: ''"query:${n}:${escape [ ''"'' ] v}"'';
      queries = mapAttrsToList mkQueryEntry cfg.queries;
    in concatStringsSep "\n"
    (if versionAtLeast config.home.stateVersion "20.03" then
      queries ++ urls
    else
      urls ++ queries) + "\n";

    home.file.".newsboat/config".text = ''
      # File generated by home-manger newsboat module
      # converted from options
      max-items ${toString cfg.maxItems}
      browser ${cfg.browser}
      reload-threads ${toString cfg.reloadThreads}
      auto-reload ${toYesNo cfg.autoReload}
      ${optionalString (cfg.reloadTime != null)
      (toString "reload-time ${toString cfg.reloadTime}")}
      prepopulate-query-feeds yes
      cleanup-on-quit ${toYesNo cfg.cleanupOnQuit}
      delete-read-articles-on-quit ${toYesNo cfg.deleteReadArticlesOnQuit}
      show-read-feeds ${toYesNo cfg.showReadFeeds}
      show-read-articles ${toYesNo cfg.showReadArticles}
      confirm-exit ${toYesNo cfg.confirmExit}
      download-full-page ${toYesNo cfg.downloadFullPage}
      history-limit ${toString cfg.historyLimit}
      ${optionalString (cfg.bookmarkCmd != null)
      (toString "bookmark-cmd ${cfg.bookmarkCmd}")}
      bookmark-interactive ${toYesNo cfg.bookmarkInteractive}
      bookmark-autopilot ${toYesNo cfg.bookmarkAutopilot}

      # extra config
      ${cfg.extraConfig}
    '';
  };
}
