{
  writeShellApplication,
  curl,
  git,
  jq,
  tokenFile,
}:
writeShellApplication {
  name = "forgejo-pr-wait";
  runtimeInputs = [
    curl
    git
    jq
  ];
  text = ''
    FORGEJO_URL="https://trev.zip"
    FORGEJO_TOKEN_FILE="${tokenFile}"
  ''
  + builtins.readFile ./forgejo-pr-wait.sh;
}
