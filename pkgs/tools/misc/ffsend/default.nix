{ stdenv, fetchFromGitLab, rustPlatform, cmake, pkgconfig, openssl
, darwin, installShellFiles

, x11Support ? stdenv.isLinux || stdenv.hostPlatform.isBSD
, xclip ? null, xsel ? null
, preferXsel ? false # if true and xsel is non-null, use it instead of xclip
}:

let
  usesX11 = stdenv.isLinux || stdenv.hostPlatform.isBSD;
in

assert (x11Support && usesX11) -> xclip != null || xsel != null;

with rustPlatform;

buildRustPackage rec {
  pname = "ffsend";
  version = "0.2.64";

  src = fetchFromGitLab {
    owner = "timvisee";
    repo = "ffsend";
    rev = "v${version}";
    sha256 = "1fgzcw0955vjypwwx3ja8sil0vxwvhsnspn1bjl869ccbnx2x4hs";
  };

  cargoSha256 = "0svmbay9waaq9fpc8lg1nys6l35xsjvkri5v1frlgxida5dzghpq";

  nativeBuildInputs = [ cmake pkgconfig installShellFiles ];
  buildInputs =
    if stdenv.isDarwin then (with darwin.apple_sdk.frameworks; [ CoreFoundation CoreServices Security AppKit ])
    else [ openssl ];

  preBuild = stdenv.lib.optionalString (x11Support && usesX11) (
    if preferXsel && xsel != null then ''
      export XSEL_PATH="${xsel}/bin/xsel"
    '' else ''
      export XCLIP_PATH="${xclip}/bin/xclip"
    ''
  );

  postInstall = ''
    installShellCompletion contrib/completions/ffsend.{bash,fish} --zsh contrib/completions/_ffsend
  '';
  # There's also .elv and .ps1 completion files but I don't know where to install those

  meta = with stdenv.lib; {
    description = "Easily and securely share files from the command line. A fully featured Firefox Send client";
    longDescription = ''
      Easily and securely share files and directories from the command line through a safe, private
      and encrypted link using a single simple command. Files are shared using the Send service and
      may be up to 2GB. Others are able to download these files with this tool, or through their
      web browser.
    '';
    homepage = "https://gitlab.com/timvisee/ffsend";
    license = licenses.gpl3;
    maintainers = with maintainers; [ lilyball equirosa ];
    platforms = platforms.unix;
  };
}
