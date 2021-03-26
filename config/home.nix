{ pkgs, ... }:

let home_directory = builtins.getEnv "HOME";
    tmp_directory = "/tmp";

    ca-bundle_crt = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    emacs-server  = "${tmp_directory}/johnw-emacs/server";

    lib = pkgs.lib;
    localconfig = import <localconfig>;

    vulcan_ethernet = "192.168.1.69";
    vulcan_wifi     = "192.168.1.90";
    athena_ethernet = "192.168.1.80";
    athena_wifi     = "192.168.1.68";
    hermes_ethernet = "192.168.1.108";
    hermes_wifi     = "192.168.1.67";

in rec {
  nixpkgs = {
    config = {
      allowUnfree = true;
      allowBroken = false;
      allowUnsupportedSystem = false;
    };

    overlays =
      let path = ../overlays; in with builtins;
      map (n: import (path + ("/" + n)))
          (filter (n: match ".*\\.nix" n != null ||
                      pathExists (path + ("/" + n + "/default.nix")))
                  (attrNames (readDir path)));
  };

  # services = {
  #   gpg-agent = {
  #     enable = true;
  #     defaultCacheTtl = 1800;
  #     enableSshSupport = true;
  #   };
  # };

  home = {
    # These are packages that should always be present in the user
    # environment, though perhaps not the machine environment.
    packages = with pkgs; [];

    sessionVariables = {
      ASPELL_CONF        = "conf ${xdg.configHome}/aspell/config;";
      B2_ACCOUNT_INFO    = "${xdg.configHome}/backblaze-b2/account_info";
      BORG_PASSCOMMAND   = "${pkgs.pass}/bin/pass show Passwords/borgbackup";
      CABAL_CONFIG       = "${xdg.configHome}/cabal/config";
      FONTCONFIG_FILE    = "${xdg.configHome}/fontconfig/fonts.conf";
      FONTCONFIG_PATH    = "${xdg.configHome}/fontconfig";
      GNUPGHOME          = "${xdg.configHome}/gnupg";
      GRAPHVIZ_DOT       = "${pkgs.graphviz}/bin/dot";
      LESSHISTFILE       = "${xdg.cacheHome}/less/history";
      LOCATE_PATH        = "${xdg.cacheHome}/locate/home.db:${xdg.cacheHome}/locate/system.db";
      NIX_CONF           = "${home_directory}/src/nix";
      PARALLEL_HOME      = "${xdg.cacheHome}/parallel";
      PASSWORD_STORE_DIR = "${home_directory}/doc/.passwords";
      RECOLL_CONFDIR     = "${xdg.configHome}/recoll";
      SCREENRC           = "${xdg.configHome}/screen/config";
      SSH_AUTH_SOCK      = "${xdg.configHome}/gnupg/S.gpg-agent.ssh";
      STARDICT_DATA_DIR  = "${xdg.dataHome}/dictionary";
      TRAVIS_CONFIG_PATH = "${xdg.configHome}/travis";
      VAGRANT_HOME       = "${xdg.dataHome}/vagrant";
      WWW_HOME           = "${xdg.cacheHome}/w3m";
      EMACS_SERVER_FILE  = "${emacs-server}";
      EDITOR             = "${pkgs.emacs}/bin/emacsclient -s ${emacs-server}";
      EMAIL              = "${programs.git.userEmail}";
      JAVA_OPTS          = "-Xverify:none";
      VULCAN_ETHERNET    = vulcan_ethernet;
      VULCAN_WIFI        = vulcan_wifi;
      ATHENA_ETHERNET    = athena_ethernet;
      ATHENA_WIFI        = athena_wifi;
      HERMES_ETHERNET    = hermes_ethernet;
      HERMES_WIFI        = hermes_wifi;

      RCLONE_PASSWORD_COMMAND        = "${pkgs.pass}/bin/pass show Passwords/rclone-b2";
      RESTIC_PASSWORD_COMMAND        = "${pkgs.pass}/bin/pass show Passwords/restic";
      VAGRANT_DEFAULT_PROVIDER       = "vmware_desktop";
      VAGRANT_VMWARE_CLONE_DIRECTORY = "${home_directory}/Machines/vagrant";
      FILTER_BRANCH_SQUELCH_WARNING  = "1";
    };

    file = builtins.listToAttrs (
      map (path: {
             name = path;
             value = {
               source = builtins.toPath("${home_directory}/src/home/${path}");
             };
           })
          [ "Library/Scripts/Applications/Download links to PDF.scpt"
            "Library/Scripts/Applications/Media Pro" ]) // {
        # ".cups".source    = "${xdg.configHome}/cups";
        # ".dbvis".source   = "${xdg.configHome}/DbVisualizer";
        # ".gist".source    = "${xdg.configHome}/gist/account_id";
        # ".jira.d".source  = "${xdg.configHome}/jira";
        # ".macbeth".source = "${xdg.configHome}/macbeth";
        # ".recoll".source  = "${xdg.configHome}/recoll";
        # ".zekr".source    = "${xdg.configHome}/zekr";

        # ".dl".source = "${home_directory}/Downloads";

        ".ledgerrc".text = ''
          --file ${home_directory}/doc/accounts/main.ledger
          --input-date-format %Y/%m/%d
          --date-format %Y/%m/%d
        '';

        # ".tmux.conf".text = ''
        #   set-option -g default-command "reattach-to-user-namespace -l ${pkgs.zsh}/bin/zsh"
        # '';

        ".curlrc".text = ''
          capath=${pkgs.cacert}/etc/ssl/certs/
          cacert=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
        '';
        ".wgetrc".text = ''
          ca_directory = ${pkgs.cacert}/etc/ssl/certs/
          ca_certificate = ${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
        '';
      };

      # activation.linkMyFiles = lib.hm.dag.entryAfter ["writeBoundary"] ''
      #   ln -s ${home_directory}/Downloads ${home_directory}/dl
      # '';
  };

  programs = {
    home-manager = {
      enable = true;
      path = "${home_directory}/src/nix/home-manager";
    };

    browserpass = {
      enable = true;
      browsers = [ "firefox" ];
    };

    direnv = {
      enable = true;
    };

    bash = {
      enable = true;
      bashrcExtra = lib.mkBefore ''
        source /etc/bashrc
      '';
    };

    zsh = rec {
      enable = true;

      dotDir = ".config/zsh";
      enableCompletion = false;
      enableAutosuggestions = true;

      history = {
        size = 50000;
        save = 500000;
        path = "${dotDir}/history";
        ignoreDups = true;
        share = true;
      };

      sessionVariables = {
        ALTERNATE_EDITOR  = "${pkgs.vim}/bin/vi";
        LC_CTYPE          = "en_US.UTF-8";
        LESS              = "-FRSXM";
        PROMPT            = "%m %~ $ ";
        PROMPT_DIRTRIM    = "2";
        RPROMPT           = "";
        TINC_USE_NIX      = "yes";
        WORDCHARS         = "";
      };

      shellAliases = {
        b      = "${pkgs.git}/bin/git b";
        l      = "${pkgs.git}/bin/git l";
        w      = "${pkgs.git}/bin/git w";
        g      = "${pkgs.gitAndTools.hub}/bin/hub";
        git    = "${pkgs.gitAndTools.hub}/bin/hub";
        ga     = "${pkgs.gitAndTools.git-annex}/bin/git-annex";
        good   = "${pkgs.git}/bin/git bisect good";
        bad    = "${pkgs.git}/bin/git bisect bad";
        ls     = "${pkgs.coreutils}/bin/ls --color=auto";
        nm     = "${pkgs.findutils}/bin/find . -name";
        par    = "${pkgs.parallel}/bin/parallel";
        rm     = "${pkgs.my-scripts}/bin/trash";
        rX     = "${pkgs.coreutils}/bin/chmod -R ugo+rX";
        scp    = "${pkgs.rsync}/bin/rsync -aP --inplace";
        wipe   = "${pkgs.srm}/bin/srm -vfr";
        switch = "${pkgs.nix-scripts}/bin/u ${localconfig.hostname} switch";
        proc   = "${pkgs.darwin.ps}/bin/ps axwwww | ${pkgs.gnugrep}/bin/grep -i";
        nstat  = "${pkgs.darwin.network_cmds}/bin/netstat -nr -f inet"
               + " | ${pkgs.gnugrep}/bin/egrep -v \"(lo0|vmnet|169\\.254|255\\.255)\""
               + " | ${pkgs.coreutils}/bin/tail -n +5";

        # Use whichever cabal is on the PATH.
        cn     = "cabal new-configure --enable-tests --enable-benchmarks";
        cnp    = "cabal new-configure --enable-tests --enable-benchmarks " +
                 "--enable-profiling --ghc-options=-fprof-auto";
        cb     = "cabal new-build";

        # Use whichever terraform is on the PATH.
        deploy = ''${pkgs.nix}/bin/nix-shell --pure --command '' +
          ''"terraform init; '' +
          ''export GITHUB_TOKEN=$(${pkgs.pass}/bin/pass show api.github.com | head -1); '' +
          ''terraform apply"'';
      };

      profileExtra = ''
        export GPG_TTY=$(tty)
        if ! pgrep -x "gpg-agent" > /dev/null; then
            ${pkgs.gnupg}/bin/gpgconf --launch gpg-agent
        fi

        . ${pkgs.z}/share/z.sh

        defaults write org.hammerspoon.Hammerspoon MJConfigFile \
            "${xdg.configHome}/hammerspoon/init.lua"

        for i in rdm msmtp privoxy tor; do
            dir=${xdg.dataHome}/$i
            if [[ ! -d $dir ]]; then mkdir -p $dir; fi
        done

        setopt extended_glob
      '';

      initExtra = lib.mkBefore ''
        export PATH=$(echo "$PATH" | sed 's/\/usr\/local\/bin:\/usr\/bin:\/bin:\/usr\/sbin:\/sbin://')
        export PATH=${home_directory}/doc/accounts/bin:$PATH
        export PATH=$PATH:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin
        export PATH=$(echo "$PATH" | sed 's/\/Applications\/VMware Fusion\.app\/Contents\/Public://')

        # DOCKER_MACHINE=$(which docker-machine)
        # if [[ -x "$DOCKER_MACHINE" ]]; then
        #     if $DOCKER_MACHINE status default > /dev/null 2>&1; then
        #         eval $($DOCKER_MACHINE env default) > /dev/null 2>&1
        #     fi
        # fi

        export SSH_AUTH_SOCK=$(${pkgs.gnupg}/bin/gpgconf --list-dirs agent-ssh-socket)

        function upload() {
            ${pkgs.lftp}/bin/lftp -u johnw@newartisans.com,$(${pkgs.pass}/bin/pass show ftp.fastmail.com | head -1) \
                ftp://johnw@newartisans.com@ftp.fastmail.com                 \
                -e "set ssl:ca-file \"${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt\"; cd /johnw.newartisans.com/files/pub ; put \"$1\" ; quit"

            file=$(basename "$1" | sed -e 's/ /%20/g')
            echo "http://ftp.newartisans.com/pub/$file" | pbcopy
        }

        if [[ $TERM == dumb || $TERM == emacs || ! -o interactive ]]; then
            unsetopt zle
            unset zle_bracketed_paste
            export PS1='%m %~ $ '
        else
           . ${xdg.configHome}/zsh/plugins/iterm2_shell_integration
           . ${xdg.configHome}/zsh/plugins/iterm2_tmux_integration
        fi
      '';

      plugins = [
        { name = "iterm2_shell_integration";
          src = pkgs.fetchurl {
            url = https://iterm2.com/shell_integration/zsh;
            sha256 = "1qm7khz19dhwgz4aln3yy5hnpdh6pc8nzxp66m1za7iifq9wrvil";
            # date = 2020-01-07T15:59:09-0800;
          };
        }
        { name = "iterm2_tmux_integration";
          src = pkgs.fetchurl {
            url = https://gist.githubusercontent.com/antifuchs/c8eca4bcb9d09a7bbbcd/raw/3ebfecdad7eece7c537a3cd4fa0510f25d02611b/iterm2_zsh_init.zsh;
            sha256 = "1v1b6yz0lihxbbg26nvz85c1hngapiv7zmk4mdl5jp0fsj6c9s8c";
            # date = 2020-01-07T15:59:13-0800;
          };
        }
      ];
    };

    git = {
      enable = true;

      userName  = "John Wiegley";
      userEmail = "johnw@newartisans.com";

      signing = {
        key = "C144D8F4F19FE630";
        signByDefault = true;
      };

      aliases = {
        amend      = "commit --amend -C HEAD";
        authors    = "!\"${pkgs.git}/bin/git log --pretty=format:%aN"
                   + " | ${pkgs.coreutils}/bin/sort"
                   + " | ${pkgs.coreutils}/bin/uniq -c"
                   + " | ${pkgs.coreutils}/bin/sort -rn\"";
        b          = "branch --color -v";
        ca         = "commit --amend";
        changes    = "diff --name-status -r";
        clone      = "clone --recursive";
        co         = "checkout";
        cp         = "cherry-pick";
        dc         = "diff --cached";
        dh         = "diff HEAD";
        ds         = "diff --staged";
        from       = "!${pkgs.git}/bin/git bisect start && ${pkgs.git}/bin/git bisect bad HEAD && ${pkgs.git}/bin/git bisect good";
        ls-ignored = "ls-files --exclude-standard --ignored --others";
        rc         = "rebase --continue";
        rh         = "reset --hard";
        ri         = "rebase --interactive";
        rs         = "rebase --skip";
        ru         = "remote update --prune";
        snap       = "!${pkgs.git}/bin/git stash"
                   + " && ${pkgs.git}/bin/git stash apply";
        snaplog    = "!${pkgs.git}/bin/git log refs/snapshots/refs/heads/"
                   + "\$(${pkgs.git}/bin/git rev-parse HEAD)";
        spull      = "!${pkgs.git}/bin/git stash"
                   + " && ${pkgs.git}/bin/git pull"
                   + " && ${pkgs.git}/bin/git stash pop";
        su         = "submodule update --init --recursive";
        undo       = "reset --soft HEAD^";
        w          = "status -sb";
        wdiff      = "diff --color-words";
        l          = "log --graph --pretty=format:'%Cred%h%Creset"
                   + " —%Cblue%d%Creset %s %Cgreen(%cr)%Creset'"
                   + " --abbrev-commit --date=relative --show-notes=*";
      };

      extraConfig = {
        core = {
          editor            = "${pkgs.emacs}/bin/emacsclient -s ${emacs-server}";
          trustctime        = false;
          fsyncobjectfiles  = true;
          # pager             = "${pkgs.less}/bin/less --tabs=4 -RFX";
          pager             = "${pkgs.gitAndTools.delta}/bin/delta --plus-color=\"#012800\" --minus-color=\"#340001\" --theme='ansi-dark'";
          logAllRefUpdates  = true;
          precomposeunicode = false;
          whitespace        = "trailing-space,space-before-tab";
        };

        interactive.diffFilter = "${pkgs.gitAndTools.delta}/bin/delta --color-only";
        branch.autosetupmerge = true;
        commit.gpgsign        = true;
        github.user           = "jwiegley";
        credential.helper     = "${pkgs.pass-git-helper}/bin/pass-git-helper";
        ghi.token             = "!${pkgs.pass}/bin/pass show api.github.com | head -1";
        hub.protocol          = "${pkgs.openssh}/bin/ssh";
        mergetool.keepBackup  = true;
        pull.rebase           = true;
        rebase.autosquash     = true;
        rerere.enabled        = true;

        "merge \"ours\"".driver   = true;
        "magithub \"ci\"".enabled = false;

        http = {
          sslCAinfo = "${ca-bundle_crt}";
          sslverify = true;
        };

        color = {
          status      = "auto";
          diff        = "auto";
          branch      = "auto";
          interactive = "auto";
          ui          = "auto";
          sh          = "auto";
        };

        push = {
          default = "tracking";
          # recurseSubmodules = "check";
        };

        "merge \"merge-changelog\"" = {
          name = "GNU-style ChangeLog merge driver";
          driver = "${pkgs.git-scripts}/bin/git-merge-changelog %O %A %B";
        };

        merge = {
          conflictstyle = "diff3";
          stat = true;
        };

        "color \"sh\"" = {
          branch      = "yellow reverse";
          workdir     = "blue bold";
          dirty       = "red";
          dirty-stash = "red";
          repo-state  = "red";
        };

        annex = {
          backends = "BLAKE2B512E";
          alwayscommit = false;
        };

        "filter \"media\"" = {
          required = true;
          clean = "${pkgs.git}/bin/git media clean %f";
          smudge = "${pkgs.git}/bin/git media smudge %f";
        };

        # submodule = {
        #   recurse = true;
        # };

        diff = {
          ignoreSubmodules = "dirty";
          renames = "copies";
          mnemonicprefix = true;
        };

        advice = {
          statusHints = false;
          pushNonFastForward = false;
          objectNameWarning = "false";
        };

        "filter \"lfs\"" = {
          clean = "${pkgs.git-lfs}/bin/git-lfs clean -- %f";
          smudge = "${pkgs.git-lfs}/bin/git-lfs smudge --skip -- %f";
          required = true;
        };

        "url \"git://github.com/ghc/packages-\"".insteadOf
          = "git://github.com/ghc/packages/";
        "url \"http://github.com/ghc/packages-\"".insteadOf
          = "http://github.com/ghc/packages/";
        "url \"https://github.com/ghc/packages-\"".insteadOf
          = "https://github.com/ghc/packages/";
        "url \"ssh://git@github.com/ghc/packages-\"".insteadOf
          = "ssh://git@github.com/ghc/packages/";
        "url \"git@github.com:/ghc/packages-\"".insteadOf
          = "git@github.com:/ghc/packages/";
      };

      ignores = [
        "#*#"
        "*.a"
        "*.aux"
        "*.dylib"
        "*.elc"
        "*.glob"
        "*.la"
        "*.o"
        "*.so"
        "*.v.d"
        "*.vo"
        "*~"
        ".clean"
        ".direnv"
        ".envrc"
        ".envrc.cache"
        ".envrc.override"
        ".ghc.environment.x86_64-darwin-*"
        ".makefile"
        "TAGS"
        "cabal.project.local"
        "dist-newstyle"
        "result"
        "result-*"
        "tags"
      ];
    };

    ssh = {
      enable = true;

      controlMaster  = "auto";
      controlPath    = "${tmp_directory}/ssh-%u-%r@%h:%p";
      controlPersist = "1800";

      forwardAgent = true;
      serverAliveInterval = 60;

      hashKnownHosts = true;
      userKnownHostsFile = "${xdg.configHome}/ssh/known_hosts";

      extraConfig = ''
        Host default
          HostName 127.0.0.1
          User vagrant
          Port 2222
          UserKnownHostsFile /dev/null
          StrictHostKeyChecking no
          PasswordAuthentication no
          IdentityFile /Users/johnw/dfinity/master/.vagrant/machines/default/vmware_desktop/private_key
          IdentitiesOnly yes
          LogLevel FATAL
      '';

      matchBlocks =
        let onHost = proxy: hostname: { inherit hostname; } //
          (if "${localconfig.hostname}" == proxy then {} else {
             proxyJump = proxy;
           }); in
        (if    "${localconfig.hostname}" == "vulcan"
            || "${localconfig.hostname}" == "hermes"
            || "${localconfig.hostname}" == "athena"
            then {
           vulcan.hostname = vulcan_ethernet;
         } else {
           vulcan = {
             hostname = "2600:1700:cf00:db0:f1b3:ab80:3419:685d";
             port = 2201;
             extraOptions = {
               "LocalForward" = "5999 127.0.0.1:5900";
             };
           };
         }) // rec {

        hermes  = onHost "vulcan" hermes_ethernet;
        athena  = onHost "vulcan" athena_ethernet;
        tank    = athena;

        # router  = { hostname = "192.168.1.98"; user = "root"; };

        nixos   = onHost "vulcan" "192.168.118.128";
        dfinity = onHost "vulcan" "192.168.118.136";
        macos   = onHost "vulcan" "172.16.20.139";
        ubuntu  = onHost "vulcan" "172.16.20.140";
        glibc   = onHost "vulcan" "172.16.20.141";

        elpa        = { hostname = "elpa.gnu.org"; user = "root"; };
        haskell_org = { host = "*haskell.org";     user = "root"; };

        savannah.hostname  = "git.sv.gnu.org";
        fencepost.hostname = "fencepost.gnu.org";
        launchpad.hostname = "bazaar.launchpad.net";
        mail.hostname      = "mail.haskell.org";

        keychain = {
          host = "*";
          extraOptions = {
            "UseKeychain"    = "yes";
            "AddKeysToAgent" = "yes";
            "IgnoreUnknown"  = "UseKeychain";
          };
        };

        id_local = {
          host = lib.concatStringsSep " " [
            "hermes" "athena" "home" "mac1*" "macos*" "nixos*" "mohajer"
            "dfinity" "smokeping" "tank" "titan" "ubuntu*" "vulcan"
          ];
          identityFile = "${xdg.configHome}/ssh/id_local";
          identitiesOnly = true;
          user = "johnw";
        };

        nix-docker = {
          hostname = "127.0.0.1";
          proxyJump = "athena";
          user = "root";
          port = 3022;
          identityFile = "${xdg.configHome}/ssh/nix-docker_rsa";
          identitiesOnly = true;
        };

        # DFINITY Machines

        id_dfinity = {
          host = lib.concatStringsSep " " [
            "hydra"
            "pa-1" "pa-darwin-1" "pa-darwin-2"
            "zrh-1" "zrh-2" "zrh-3" "zrh-darwin-1"
          ];
          identityFile = "${xdg.configHome}/ssh/id_dfinity";
          identitiesOnly = true;
        };

        # DFINITY Machines on AWS

        hydra = {
          hostname = "hydra.dfinity.systems";
          user = "ec2-user";
        };

        # DFINITY Machines in Palo Alto

        pa-1 = {
          hostname = "pa-linux-1.dfinity.systems";
          user = "johnw";
        };

        # This requires a VPN connection to the DFINITY network.

        pa-darwin-1 = {
          hostname = "pa-darwin-1.dfinity.systems";
          user = "dfinity";
        };

        pa-darwin-2 = {
          hostname = "pa-darwin-2.dfinity.systems";
          user = "dfnmain";
        };

        # DFINITY Machines in Zurich

        zrh-1 = {
          hostname = "zrh-linux-1.dfinity.systems";
          user = "johnw";
        };

        zrh-2 = {
          hostname = "zrh-linux-2.dfinity.systems";
          user = "johnw";
        };

        zrh-3 = {
          hostname = "zrh-linux-3.dfinity.systems";
          user = "johnw";
        };

        zrh-darwin-1 = {
          hostname = "10.129.0.99";
          user = "dfinity";
        };

        demo-1.hostname = "10.11.18.1";
        demo-2.hostname = "10.11.18.2";
        demo-3.hostname = "10.11.18.3";
        demo-4.hostname = "10.11.18.4";

        demo-options = {
          host = lib.concatStringsSep " " [
            "demo-*"
          ];
          # proxyJump = "zrh-3";
          user = "root";
          extraOptions = {
            "PreferredAuthentications" = "password";
            "PubkeyAuthentication"     = "no";
          };
        };
      };
    };
  };

  xdg = {
    enable = true;

    configHome = "${home_directory}/.config";
    dataHome   = "${home_directory}/.local/share";
    cacheHome  = "${home_directory}/.cache";

    configFile."gnupg/gpg-agent.conf".text = ''
      enable-ssh-support
      default-cache-ttl 86400
      max-cache-ttl 86400
      pinentry-program ${pkgs.pinentry_mac}/Applications/pinentry-mac.app/Contents/MacOS/pinentry-mac
    '';

    configFile."aspell/config".text = ''
      local-data-dir ${pkgs.aspell}/lib/aspell
      data-dir ${pkgs.aspellDicts.en}/lib/aspell
      personal ${xdg.configHome}/aspell/en_US.personal
      repl ${xdg.configHome}/aspell/en_US.repl
    '';

    configFile."recoll/mimeview".text = ''
      xallexcepts- = application/pdf
      xallexcepts+ =
      [view]
      application/pdf = ${pkgs.emacs}/bin/emacsclient -n -s ${emacs-server} --eval '(org-pdfview-open "%f::%p")'
    '';

    configFile."msmtp".text = ''
      defaults
      tls on
      tls_starttls on
      tls_trust_file ${ca-bundle_crt}

      account fastmail
      host smtp.fastmail.com
      port 587
      auth on
      user ${programs.git.userEmail}
      passwordeval ${pkgs.pass}/bin/pass show smtp.fastmail.com
      from ${programs.git.userEmail}
      logfile ${xdg.dataHome}/msmtp/msmtp.log
    '';

    configFile."fetchmail/config".text = ''
      poll imap.fastmail.com protocol IMAP port 993 auth password
        user '${programs.git.userEmail}' there is johnw here
        ssl sslcertck sslcertfile "${ca-bundle_crt}"
        folder INBOX
        fetchall
        mda "${pkgs.dovecot}/libexec/dovecot/dovecot-lda -c /etc/dovecot/dovecot.conf -e"
    '';

    configFile."fetchmail/config-lists".text = ''
      poll imap.fastmail.com protocol IMAP port 993 auth password
        user '${programs.git.userEmail}' there is johnw here
        ssl sslcertck sslcertfile "${ca-bundle_crt}"
        folder 'Lists'
        fetchall
        mda "${pkgs.dovecot}/libexec/dovecot/dovecot-lda -c /etc/dovecot/dovecot.conf -e -m list.misc"
    '';
  };
}
