{
  stdenvNoCC,
  fetchFromGitHub,
  fetchpatch,
  fetchurl,
  dart-sass,
}:
stdenvNoCC.mkDerivation {
  pname = "catppuccin-gitea-sky";
  version = "0-unstable-2026-04-26";

  src = fetchFromGitHub {
    owner = "catppuccin";
    repo = "gitea";
    rev = "6a789704686ec13178a13cd84bf1e30db191a437";
    hash = "sha256-18Ykth7C2KJF0J3E215Z5LI5NIwwT3dCWQIXoSgQFXw=";
  };

  patches = [
    # https://github.com/catppuccin/gitea/pull/92
    (fetchpatch {
      url = "https://github.com/cometship/gitea/compare/6a789704686ec13178a13cd84bf1e30db191a437...a7c957f94a43c094a42b3116e1f50ce7449715ea.diff";
      hash = "sha256-whsdJ+4ofLux4ZiXE8vTqz1bD0EGB57knNf7dSiVkaU=";
    })
  ];

  palette = fetchurl {
    url = "https://registry.npmjs.org/@catppuccin/palette/-/palette-1.7.1.tgz";
    hash = "sha256-P+v8jjt+Lww94n4n9zHVbn8XPpF+hXBFit0qBU7GScQ=";
  };

  nativeBuildInputs = [ dart-sass ];

  buildPhase = ''
    runHook preBuild

    mkdir -p node_modules/@catppuccin/palette dist
    tar -xzf $palette -C node_modules/@catppuccin/palette --strip-components=1

    for flavor in latte frappe macchiato mocha; do
      isDark=true
      [ "$flavor" = latte ] && isDark=false
      cat > wrapper.scss <<EOF
    @import "@catppuccin/palette/scss/$flavor";
    \$accent: \$sky;
    \$isDark: $isDark;
    @import "theme";
    EOF
      sass --no-source-map --quiet --load-path=src --load-path=node_modules \
        wrapper.scss "dist/theme-catppuccin-$flavor-sky.css"
    done

    cat > dist/theme-catppuccin-sky-auto.css <<EOF
    @import "./theme-catppuccin-latte-sky.css" (prefers-color-scheme: light);
    @import "./theme-catppuccin-mocha-sky.css" (prefers-color-scheme: dark);
    EOF

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    cp -r dist $out
    runHook postInstall
  '';
}
