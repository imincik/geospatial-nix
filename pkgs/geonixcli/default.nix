{ stdenv
, lib
, makeWrapper
, bash
, jq
}:

stdenv.mkDerivation rec {
  pname = "geonixcli";
  version = "0.1.0";

  src = ./.;

  unpackPhase = "true";
  buildPhase = "true";

  buildInputs = [ bash jq ];
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    mkdir -p $out/bin
    cp $src/geonix.sh $out/bin/geonix
    chmod +x $out/bin/geonix

    wrapProgram $out/bin/geonix --prefix PATH : ${lib.makeBinPath [ bash jq ]}
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
