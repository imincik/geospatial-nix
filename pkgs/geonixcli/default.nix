{ stdenv
, lib
, makeWrapper
, bash
, jq
, shellcheck
}:

stdenv.mkDerivation rec {
  pname = "geonixcli";
  version = "0.1.0";

  src = ./.;

  unpackPhase = "true";
  buildPhase = "true";

  buildInputs = [ bash jq ];
  nativeCheckInputs = [ shellcheck ];
  nativeBuildInputs = [ makeWrapper ];

  doCheck = true;
  checkPhase = ''shellcheck $src/geonix.bash'';

  installPhase = ''
    mkdir -p $out/bin $out/nix

    cp -a $src/templates $out/

    cp $src/geonix.bash $out/bin/geonix
    chmod +x $out/bin/geonix

    wrapProgram $out/bin/geonix \
      --set GEONIX_TEMPLATES_DIR $out/templates \
      --prefix PATH : ${lib.makeBinPath [ bash jq ]}
  '';

  meta = with lib; {
    description = "Geonix convenience tools";
    homepage = "https://github.com/imincik/geonix";
    license = licenses.mit;
    platforms = platforms.unix;
    maintainers = with maintainers; [ imincik ];
    mainProgram = "geonix";
  };
}
