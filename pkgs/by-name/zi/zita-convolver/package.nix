{
  lib,
  stdenv,
  fetchzip,
  fftwFloat,
}:

stdenv.mkDerivation rec {
  pname = "zita-convolver";
  version = "4.0.3";
  src = fetchzip {
    url = "https://kokkinizita.linuxaudio.org/linuxaudio/downloads/zita-convolver-${version}.tar.bz2";
    hash = "sha256-f8a3sLcN6GMPV/8E/faqMYkJdUa7WqmQBrehH6kCJtc=";
  };

  sourceRoot = "${src.name}/source";
  buildInputs = [ fftwFloat ];

  postPatch = ''
    substituteInPlace Makefile \
      --replace-quiet "ldconfig" ""
  '';

  makeFlags = [
    "PREFIX=$(out)"
    "SUFFIX="
  ];

  postInstall = ''
    # create lib link for building apps
    ln -s $out/lib/libzita-convolver.so.${version} $out/lib/libzita-convolver.so.${lib.versions.major version}
  '';

  meta = {
    description = "Convolution library by Fons Adriaensen";
    homepage = "https://kokkinizita.linuxaudio.org/linuxaudio/index.html";
    license = lib.licenses.gpl3Plus;
    maintainers = [ lib.maintainers.magnetophon ];
    platforms = lib.platforms.unix;
  };
}
