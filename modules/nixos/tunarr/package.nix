{
  lib,
  stdenv,
  fetchurl,
  makeWrapper,
  ffmpeg-full,
  autoPatchelfHook,
}:
stdenv.mkDerivation rec {
  pname = "tunarr";
  version = "0.22.12";

  src = fetchurl {
    url = "https://github.com/chrisbenincasa/tunarr/releases/download/v${version}/tunarr-linux-x64";
    hash = "";  # Will be filled after first build
  };

  nativeBuildInputs = [
    makeWrapper
    autoPatchelfHook
  ];

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp $src $out/bin/tunarr
    chmod +x $out/bin/tunarr

    wrapProgram $out/bin/tunarr \
      --prefix PATH : ${lib.makeBinPath [ffmpeg-full]}

    runHook postInstall
  '';

  meta = with lib; {
    description = "Create a classic TV experience using your own media";
    longDescription = ''
      Tunarr allows you to create and configure live TV channels using media
      from your Plex, Jellyfin, or Emby servers. Configure your channels,
      programs, commercials, and settings using the Tunarr web UI, and watch
      your channels by adding the spoofed Tunarr HDHomerun tuner to your
      media server.
    '';
    homepage = "https://tunarr.com/";
    changelog = "https://github.com/chrisbenincasa/tunarr/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = [];
    mainProgram = "tunarr";
    platforms = ["x86_64-linux"];
  };
}
