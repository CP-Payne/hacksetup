# Vim keys on the command line. Sourced at the end of ~/.zshrc.
# Esc = normal mode (block cursor), i/a/c... = insert mode (bar cursor).
bindkey -v
export KEYTIMEOUT=1                # switch to normal mode as soon as Esc is pressed

# Plain vi mode makes insert mode awkward, so keep the usual editing keys
bindkey -M viins '^?' backward-delete-char
bindkey -M viins '^H' backward-delete-char
bindkey -M viins '^W' backward-kill-word
bindkey -M viins '^U' backward-kill-line
bindkey -M viins '^A' beginning-of-line    # in tmux, press Ctrl+A twice
bindkey -M viins '^E' end-of-line
bindkey -M viins '^R' history-incremental-search-backward

for km in viins vicmd; do
  bindkey -M $km '^[[3~'    delete-char
  bindkey -M $km '^[[H'     beginning-of-line
  bindkey -M $km '^[[1~'    beginning-of-line
  bindkey -M $km '^[[F'     end-of-line
  bindkey -M $km '^[[4~'    end-of-line
  bindkey -M $km '^[[1;5C'  forward-word
  bindkey -M $km '^[[1;5D'  backward-word
done

# ci" ci' ci( ci[ ci{ ci< and the a versions. Good for <PLACEHOLDERS>.
autoload -Uz select-quoted select-bracketed
zle -N select-quoted
zle -N select-bracketed
for km in viopp visual; do
  for c in {a,i}{\',\",\`}; do bindkey -M $km "$c" select-quoted; done
  for c in {a,i}{\(,\),\[,\],\{,\},\<,\>,b,B}; do bindkey -M $km "$c" select-bracketed; done
done
unset km c

# Block cursor in normal mode, bar in insert mode
zle-keymap-select() {
  if [[ $KEYMAP == vicmd ]]; then printf '\e[2 q'; else printf '\e[6 q'; fi
}
zle-line-init() { printf '\e[6 q'; }
zle-line-finish() { printf '\e[2 q'; }   # programs start with a normal cursor
zle -N zle-keymap-select
zle -N zle-line-init
zle -N zle-line-finish
