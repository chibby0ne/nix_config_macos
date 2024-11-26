{
  description = "Example Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {
      
      nixpkgs.config.allowUnfree = true;


      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages = with pkgs; [
	      neovim
	      tmux
	      alacritty
	      mkalias
	      obsidian

	      python312Packages.ipython
	      python312
	      gopls
	      pyright
	      go
	      zulu
	      jetbrains.idea-community
	      vscode

	      maven
	      nodejs
	      poetry
	      virtualenv

	      kubernetes-helm
	      google-cloud-sdk

	      git
	      gh
	      procps


	      # ui-client
	      nodejs_latest
	      yarn

	      bat
	      fd
	      fzf
	      htop
	      jq
	      lsof
	      ripgrep
	      tree
	      tokei
	      wget
	      rsync
	      nix-index

	      nginx

	      keepassxc


	      # LSPs
	      gopls

      ];

      fonts.packages = with pkgs; [
        nerdfonts
	source-code-pro
      ];
     
      homebrew = {
        enable = true;
	brews = [
	  "mas"
	  "jenv"
	  "goenv"
	  "podman"
	  "direnv"
	  "ko"
	];
	casks = [
	  "hammerspoon"
	  "firefox"
	  "google-chrome"
	  "the-unarchiver"
	  "zulu@8"
	  "zulu@17"
	  "zulu@21"
	  "rancher"
	  "podman-desktop"
	  "virtualbox"
	  "openshift-client"
	  # Comes from the hashicorp/tap tap
	  "hashicorp/tap/hashicorp-vagrant"
	];
	taps = [
	  "hashicorp/tap"
	];
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
	  "${pkgs.alacritty}/Applications/Alacritty.app"
	  "/Applications/Slack.app"
	  "/Applications/Firefox.app"
	  "/Applications/1Password.app"
	  "${pkgs.jetbrains.idea-community}/Applications/IntelliJ IDEA CE.app"
	  "${pkgs.vscode}/Applications/Visual Studio Code.app"
	  "/Applications/Podman Desktop.app"
	  "/Applications/Rancher Desktop.app"
	  "${pkgs.obsidian}/Applications/Obsidian.app"
	];
	finder.FXPreferredViewStyle = "clmv";
	loginwindow.GuestEnabled = false;
	NSGlobalDomain.AppleICUForce24HourTime = true;
	NSGlobalDomain.AppleInterfaceStyle = "Dark";
	NSGlobalDomain.KeyRepeat = 2;
      };

      # Auto upgrade nix package and the daemon service.
      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";

      # Create /etc/zshrc that loads the nix-darwin environment.
      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

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
      in
        pkgs.lib.mkForce ''
	  # Set up applications.
	  echo "setting up /Applications..." >&2
	  rm -rf /Applications/Nix\ Apps
	  mkdir -p /Applications/Nix\ Apps
	  find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
	  while read src; do
	    app_name=$(basename "$src")
	    echo "copying $src" >&2
	    ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
	  done
	'';
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#simple
    darwinConfigurations."macbookpro" = nix-darwin.lib.darwinSystem {
      modules = [
      	configuration
	nix-homebrew.darwinModules.nix-homebrew
	{
	  nix-homebrew = {
	    enable = true;
	    # Apple Silicon Only
	    enableRosetta = true;
	    # User owning homebrew prefix
	    user = "antoniogutierrez";
	  };
	}
      ];
    };

    # Expose the package set, including overlays, for convenience.
    darwinPackages = self.darwinConfigurations."macbookpro".pkgs;
  };
}
