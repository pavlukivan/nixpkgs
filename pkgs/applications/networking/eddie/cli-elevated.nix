{ stdenv
, openvpn
, version
, src
}:

stdenv.mkDerivation {
  inherit version src;

  pname = "eddie-cli-elevated";

  postPatch = ''
    cd src/App.CLI.Linux.Elevated
    chmod +x *.sh
    patchShebangs --build .
    sed -ri \
      's%expectedOpenVpnHash = "([0-9a-f]{64})";%expectedOpenVpnHash = "'"$(sha256sum ${openvpn}/bin/openvpn)"'";%g' \
      ../App.CLI.Common.Elevated/hashes.h
  '';

  buildPhase = ''
    ./build.sh Release STANDARD
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp bin/eddie-cli-elevated $out/bin
  '';
}
