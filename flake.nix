{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, }:
    let

      username = "antoniogutierrez";
      configuration = { pkgs, config, ... }: {

        nixpkgs.config.allowUnfree = true;

        # List packages installed in system profile. To search by name, run:
        # $ nix-env -qaP | grep wget
        environment.systemPackages = with pkgs;
          let
            gdk = google-cloud-sdk.withExtraComponents
              (with google-cloud-sdk.components; [ gke-gcloud-auth-plugin ]);
            languageServerPackages = with pkgs; [
              bash-language-server
              basedpyright
              gopls
              pyright
              nil
              nixd
              pyright
              rust-analyzer
              lua-language-server
              luajitPackages.luarocks
              # llvmPackages_20.clangUseLLVM
              uv
              nixfmt-classic
              yaml-language-server
            ];
            languagePackages = with pkgs; [
              python312Packages.ipython
              python312
              maven
              nodejs
              nodejs_latest
              virtualenv
              yarn
              cargo
              go
            ];
            shellUtilPackages = with pkgs; [
              bat
              fd
              fzf
              git
              git-lfs
              gh
              gnused
              htop
              jq
              lsof
              nix-index
              ripgrep
              rsync
              tree
              tokei
              wget
              yq
              trivy
              jfrog-cli
              coreutils
            ];
            toolPackages = with pkgs; [
              neovim
              tmux
              alacritty
              mkalias
              linkerd_edge
              httpie
              procps
              keepassxc
              websocat
              netcat-gnu
              socat
              postman
              asciinema
              pre-commit
            ];
            kubernetesPackages = with pkgs; [
              podman
              kubebuilder
              kafkactl
              awscli2
              skopeo
              eksctl
              colima
              docker-client
              docker-buildx
              kubernetes-helm
              kubectl
              minikube
              kubebuilder
              ibmcloud-cli
            ];
            idePackages = with pkgs; [ jetbrains.idea-community vscode ];
          in [ gdk ] ++ languageServerPackages ++ languagePackages
          ++ shellUtilPackages ++ toolPackages ++ kubernetesPackages
          ++ idePackages;

        users.users.antoniogutierrez.shell = pkgs.fish;

        fonts.packages = with pkgs;
          [ source-code-pro office-code-pro ]
          ++ builtins.filter lib.attrsets.isDerivation
          (builtins.attrValues pkgs.nerd-fonts);

        homebrew = {
          enable = true;
          brews = [
            "mas"
            "jenv"
            "direnv"
            "ko"
            "docker-credential-helper"
            "nvm"
            "qemu"
            "cfergeau/crc/vfkit"
            "nginx"
            "azure-cli"
            "openshift-cli"
            "yabai"
            "skhd"
          ];
          casks = [
            "gimp"
            "ghostty"
            "obsidian"
            "slack"
            "1password"
            "hammerspoon"
            "firefox"
            "google-chrome"
            "the-unarchiver"
            "zulu@8"
            "zulu@11"
            "zulu@17"
            "zulu@21"
            "graalvm-jdk"
            "karabiner-elements"
            # "oracle-jdk"
            # Comes from the hashicorp/tap tap
            "hashicorp/tap/hashicorp-vagrant"
            "wireshark-chmodbpf"
            "rancher"
          ];
          taps = [ "hashicorp/tap" "cfergeau/crc" "koekeishiya/formulae" ];
          #masApps = {
          #  "Yoink" = 457622435;
          #};
          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
        };

        system.defaults = {
          dock.autohide = true;
          dock.persistent-apps = [
            "/Applications/Ghostty.app"
            "/Applications/Slack.app"
            "/Applications/Firefox.app"
            "/Applications/1Password.app"
            "/Applications/Rancher Desktop.app"
            "${pkgs.jetbrains.idea-community}/Applications/IntelliJ IDEA CE.app"
            "${pkgs.vscode}/Applications/Visual Studio Code.app"
            "/Applications/Obsidian.app"
          ];
          finder.FXPreferredViewStyle = "clmv";
          loginwindow.GuestEnabled = false;
          NSGlobalDomain.AppleICUForce24HourTime = true;
          NSGlobalDomain.AppleInterfaceStyle = "Dark";
          NSGlobalDomain.KeyRepeat = 2;
        };
        system.primaryUser = username;

        # Auto upgrade nix package and the daemon service.
        # services.nix-daemon.enable = true;
        # nix.package = pkgs.nix;

        # Necessary for using flakes on this system.
        nix.settings.experimental-features = "nix-command flakes";

        # Create /etc/zshrc that loads the nix-darwin environment.
        # programs.zsh.enable = true; # default shell on catalina
        programs.fish.enable = true;

        # Set Git commit hash for darwin-version.
        system.configurationRevision = self.rev or self.dirtyRev or null;

        # Used for backwards compatibility, please read the changelog before changing.
        # $ darwin-rebuild changelog
        system.stateVersion = 5;

        # The platform the configuration will be used on.
        nixpkgs.hostPlatform = "aarch64-darwin";

        system.activationScripts.applications.text = let
          env = pkgs.buildEnv {
            name = "system-applications";
            paths = config.environment.systemPackages;
            pathsToLink = "/Applications";
          };
        in pkgs.lib.mkForce
        "  # Set up applications.\n  echo \"setting up /Applications...\" >&2\n  rm -rf /Applications/Nix\\ Apps\n  mkdir -p /Applications/Nix\\ Apps\n  find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |\n  while read -r src; do\n    app_name=$(basename \"$src\")\n    echo \"copying $src\" >&2\n    ${pkgs.mkalias}/bin/mkalias \"$src\" \"/Applications/Nix Apps/$app_name\"\n  done\n";
      };
    in {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#MacBook-Pro-von-Antonio
      darwinConfigurations."MacBook-Pro-von-Antonio" =
        nix-darwin.lib.darwinSystem {
          modules = [
            configuration
            nix-homebrew.darwinModules.nix-homebrew
            {
              nix-homebrew = {
                enable = true;
                # Apple Silicon Only
                enableRosetta = true;
                # User owning homebrew prefix
                user = username;
              };
            }
          ];
        };

      # Expose the package set, including overlays, for convenience.
      darwinPackages = self.darwinConfigurations."MacBook-Pro-von-Antonio".pkgs;
    };
}
