# My Aliases Plugin
# A configurable plugin for personal aliases with auto-detection support
#
# Configuration (set in .zshrc before loading oh-my-zsh):
#   MY_ALIASES_DISABLED=(kubectl rust)  # Disable specific modules
#   MY_ALIASES_AUTO_DETECT=true         # Auto-detect tool availability (default: true)

# Set defaults
: ${MY_ALIASES_AUTO_DETECT:=true}
: ${MY_ALIASES_DISABLED:=()}

# Helper function to check if module is enabled
_my_aliases_enabled() {
  local module=$1
  
  # Check if explicitly disabled
  (( ${MY_ALIASES_DISABLED[(Ie)$module]} )) && return 1
  
  # Auto-detect if enabled
  if [[ "$MY_ALIASES_AUTO_DETECT" == "true" ]]; then
    case $module in
      kubectl) (( $+commands[kubectl] )) || return 1 ;;
      rust)    (( $+commands[cargo] )) || return 1 ;;
      git)     (( $+commands[git] )) || return 1 ;;
    esac
  fi
  
  return 0
}

# Load enabled modules
for module in rust git kubectl ohmyzsh project utility; do
  if _my_aliases_enabled $module; then
    source "${0:A:h}/lib/${module}.zsh"
  fi
done

unset module
