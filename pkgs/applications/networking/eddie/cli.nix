{ lib
, fetchFromGitHub
, buildDotnetModule
, callPackage
, eddie-elevated ? null
, eddie-native ? null
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
in

buildDotnetModule {
  inherit version src;

  pname = "eddie-cli";

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

  projectFile = "App.CLI.Linux/App.CLI.Linux.net6.csproj";
  nugetDeps = ./deps-cli.nix;

  executables = [ "App.CLI.Linux.net6" ];
  makeWrapperArgs = [ "--prefix PATH : ${runtimePath}" ];

  postInstall = ''
    mkdir -p $out/lib/eddie-cli
    rm -rf ../common/webui
    cp -r ../common $out/lib/eddie-cli/res
    cp ${native}/lib/* ${elevated}/bin/* $out/lib/eddie-cli
    mkdir -p $out/bin
  '';

  postFixup = ''
    mv $out/bin/App.CLI.Linux.net6 $out/bin/eddie-cli
  '';

  meta = with lib; {
    description = "OpenVPN and WireGuard client with AirVPN integration (CLI version)";
    homepage = "https://eddie.website/";
    changelog = "https://eddie.website/changelog/?software=client&format=html";
    maintainers = with maintainers; [ chayleaf ];
    license = licenses.gpl3Plus;
    platforms = platforms.linux;
  };
}
