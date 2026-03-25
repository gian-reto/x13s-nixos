{
  stdenv,
  fetchurl,
  innoextract,
}:
stdenv.mkDerivation {
  name = "uefi";
  version = "1.67";

  src = fetchurl {
    url = "https://download.lenovo.com/pccbbs/mobiles/n3huj25w.exe";
    hash = "sha256-LQbKh+Ncw/lTVnDenLUyyWhG4ilftK2eAKjnzJHTA7I=";
  };

  nativeBuildInputs = [innoextract];

  unpackPhase = ''
    innoextract $src
  '';

  doBuild = false;

  installPhase = ''
    mkdir --parent $out/{EFI/Boot,Flash}
    cp code\$GetExtractPath\$/Rfs/Usb/Bootaa64.efi $out/EFI/Boot/
    cp -r code\$GetExtractPath\$/Rfs/Fw/* $out/Flash/
  '';
}
