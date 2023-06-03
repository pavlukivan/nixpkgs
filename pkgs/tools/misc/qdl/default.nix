{ lib, stdenv, fetchFromGitHub, libxml2, systemd, pkg-config }:

stdenv.mkDerivation {
  pname   = "qdl";
  version = "unstable-2023-04-11";

  src = fetchFromGitHub {
    owner = "andersson";
    repo  = "qdl";
    rev   = "3b22df2bc7de02d867334af3a7aa8606db4f8cdd";
    hash  = "sha256-2sL9HX73APTn9nQOx1Efdkz9F4bNASPMVFMx6YOqxyc=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ systemd libxml2 ];

  installPhase = ''
    runHook preInstall
    install -Dm755 ./qdl -t $out/bin
    runHook postInstall
  '';

  meta = with lib; {
    homepage    = "https://github.com/andersson/qdl";
    description = "Tool for flashing images to Qualcomm devices";
    license     = licenses.bsd3;
    maintainers = with maintainers; [ muscaln ];
    platforms   = platforms.linux;
  };
}
