if [[ "$(uname -r)" == *microsoft* ]]; then
  export PATH="$PATH:/mnt/c/WINDOWS:/mnt/c/WINDOWS/System32/WindowsPowerShell/v1.0:/mnt/c/Users/${WIN_USER}/AppData/Local/Programs/Microsoft VS Code/bin:/mnt/c/Program Files/Docker/Docker/resources/bin:/mnt/c/ProgramData/DockerDesktop/version-bin"

  # [ -n $WSL_AUTH_SOCK ] && export SSH_AUTH_SOCK=$WSL_AUTH_SOCK

  export SSH_AUTH_SOCK=$HOME/.ssh/agent.sock
  ss -a | grep -q $SSH_AUTH_SOCK
  if [ $? -ne 0 ]; then
      rm -f $SSH_AUTH_SOCK
      ( setsid socat UNIX-LISTEN:$SSH_AUTH_SOCK,fork EXEC:"/mnt/c/opt/wsl-ssh-agent/npiperelay.exe -ei -s //./pipe/openssh-ssh-agent",nofork & ) >/dev/null 2>&1
  fi
fi
