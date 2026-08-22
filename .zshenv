skip_global_compinit=1

typeset -gU path fpath

case "$OSTYPE" in
  darwin*) typeset -g _OS_IS_MACOS=1 ;;
  linux*)  typeset -g _OS_IS_LINUX=1 ;;
esac
[[ -n "$_OS_IS_LINUX" && -n "$WSL_DISTRO_NAME$WSL_INTEROP" ]] && typeset -g _OS_IS_WSL=1
