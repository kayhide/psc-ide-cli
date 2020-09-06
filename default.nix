{ pkgs ? import <nixpkgs> {}
}:

let
  inherit (pkgs) lib;
  inherit (pkgs) stdenv;

in

stdenv.mkDerivation rec {
  pname = "psc-ide-cli";
  version = "0.1.0";

  src = ./src;

  nativeBuildInputs = with pkgs; [
    makeWrapper
  ];

  buildInputs = with pkgs; [
    bash
    coreutils
    gnugrep
    gnused
    jq
    libressl
    procps
  ];

  installPhase = ''
    mkdir -p $out/bin
    cp -r . $out/src
    mv $out/src/psc-ide-cli $out/bin
    wrapProgram $out/bin/psc-ide-cli \
      --set VERSION '${version}' \
      --set SRC_PATH $out/src \
      --prefix PATH : $bash/bin \
      --prefix PATH : $coreutils/bin \
      --prefix PATH : $gnugrep/bin \
      --prefix PATH : $gnused/bin \
      --prefix PATH : $jq/bin \
      --prefix PATH : $libressl/bin \
      --prefix PATH : $procps/bin \
      --argv0 psc-ide-cli
  '';

  meta = with lib; {
    description = "CLI tool to talk with psc ide server";
    license = licenses.mit;
    maintainers = with maintainers; [ kayhide ];
  };
}
