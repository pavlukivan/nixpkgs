{ stdenv
, curl
, version
, src
}:

stdenv.mkDerivation {
  inherit version src;

  pname = "eddie-native";

  buildInputs = [ curl ];

  postPatch = ''
    cd src/Lib.Platform.Linux.Native
    chmod +x *.sh
    patchShebangs --build .
  '';

  buildPhase = ''
    ./build.sh Release
  '';

  installPhase = ''
    mkdir -p $out/lib
    cp bin/libLib.Platform.Linux.Native.so $out/lib
  '';
}
