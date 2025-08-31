{
  version,
  hash,
}: {
  lib,
  stdenv,
  bubblewrap,
  buildFHSEnv,
  breakpointHook,
  fakeroot,
  fetchurl,
  glibc,
  rsync,
}: let
  fhsEnv = buildFHSEnv {
    name = "mplab-x-build-fhs-env";
    targetPkgs = pkgs: [fakeroot glibc];
  };
in
  stdenv.mkDerivation rec {
    # See https://www.microchip.com/en-us/tools-resources/archives/mplab-ecosystem for microchip installer back-catalogue
    # pname = "microchip-xc8-unwrapped";
    pname = "xc8";
    inherit version;
    src = fetchurl {
      url = "https://ww1.microchip.com/downloads/aemDocuments/documents/DEV/ProductDocuments/SoftwareTools/xc8-v${version}-full-install-linux-x64-installer.run";
      # N.B. Nix uses a 32-bit hash encoding. Use 'nix hash path <filename>' to generate
      inherit hash;
    };

    nativeBuildInputs = [bubblewrap rsync breakpointHook];

    unpackPhase = ''
      runHook preUnpack

      install $src installer.run

      runHook postUnpack
    '';
    installPhase = ''
      runHook preInstall

      rsync -a ${fhsEnv.fhsenv}/ chroot/
      find chroot -type d -exec chmod 755 {} \;
      echo "root:x:0:0:root:/root:/bin/bash" > chroot/etc/passwd
      echo "root:x:0:root" > chroot/etc/group
      mkdir -p chroot/tmp/home

      bwrap \
        --bind chroot / \
        --bind /nix /nix \
        --ro-bind installer.run /installer \
        --setenv HOME /tmp/home \
        -- /bin/fakeroot /installer \
        --LicenseType FreeMode \
        --mode unattended \
        --netservername localhost \
        --ModifyAll 0 \
        --debuglevel 4 \
        --prefix $out

      runHook postInstall
    '';
    dontFixup = true;

    meta = with lib; {
      homepage = "https://www.microchip.com/en-us/tools-resources/develop/mplab-xc-compilers";
      description = "Microchip's MPLAB XC8 C compiler toolchain for all 8-bit PIC microcontrollers (MCUs)";
      license = licenses.unfree;
      maintainers = with maintainers; [remexre nyadiia];
      platforms = ["x86_64-linux"];
    };
  }
