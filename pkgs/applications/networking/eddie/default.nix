{ lib
, fetchFromGitHub
, buildDotnetModule
, callPackage
, eddie-elevated ? null
, eddie-native ? null
, project ? "cli"
# bin path
, openvpn
, stunnel # ssl tunnel
, openssh # ssh tunnel
, curl # curl binary may be used for fetching (it seems to be a dead code path, do it just in case)
, update-resolv-conf # used for changing dns
# TODO: hummingbird (a custom OpenVPN client by AirVPN)?
}:

let
  version = "2.23.1";
  src = fetchFromGitHub {
    owner = "AirVPN";
    repo = "Eddie";
    rev = "c7a44359a4b1972a20753a8505c98437c06f8b7a";
    sha256 = "sha256-LkEGPZINmUNpa9yRNQ4R8TPkJc2P2MmzqyQ6pOUdm94=";
  };
  elevated = if eddie-elevated != null then eddie-elevated
             else callPackage ./cli-elevated.nix { inherit version src; };
  native = if eddie-native != null then eddie-native
           else callPackage ./native.nix { inherit version src; };

  runtimePath = lib.makeBinPath [ openvpn stunnel openssh curl update-resolv-conf ];
  projectName = {
    cli = "App.CLI.Linux";
    ui = "App.Forms.Linux";
    ui3 = "UI.GTK.Linux";
  }.${project};
  nugetDeps = {
    cli = ./deps-cli.nix;
    ui = ./deps-ui.nix;
    ui3 = ./deps-ui3.nix;
  }.${project};
  app = {
    cli = "eddie-cli";
    ui = "eddie-ui";
    ui3 = "eddie-ui";
  }.${project};
in

buildDotnetModule {
  inherit version src nugetDeps;

  pname = app;

  patches = [ ./fix-script-path.patch ];

  postPatch = ''
    echo <<EOF >src/eddie.linux.postbuild.sh
    #!/bin/sh
    exit 0
    EOF
    chmod +x **/*.sh
    patchShebangs --build **/*.sh
    cd src
  '';

  projectFile = "${projectName}/${projectName}.net6.csproj";

  executables = [ "${projectName}.net6" ];
  makeWrapperArgs = [ "--prefix PATH : ${runtimePath}" ];

  postInstall = ''
    mkdir -p $out/lib/${app}
    ${lib.optionalString (project != "ui3") "rm -rf ../common/webui"}
    cp -r ../common $out/lib/${app}/res
    cp ${native}/lib/* ${elevated}/bin/* $out/lib/${app}
    mkdir -p $out/bin
  '';

  postFixup = ''
    mv $out/bin/${projectName}.net6 $out/bin/${app}
  '';

  meta = with lib; {
    description = "OpenVPN and WireGuard client with AirVPN integration";
    homepage = "https://eddie.website/";
    changelog = "https://eddie.website/changelog/?software=client&format=html";
    maintainers = with maintainers; [ chayleaf ];
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
