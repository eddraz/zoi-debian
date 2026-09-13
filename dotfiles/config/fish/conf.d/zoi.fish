# zoi-debian: keep user tools on PATH in every foot+fish session.
fish_add_path ~/.local/bin
fish_add_path /usr/local/go/bin
fish_add_path ~/go/bin
fish_add_path ~/.cargo/bin
fish_add_path ~/.deno/bin
fish_add_path ~/.bun/bin
for d in ~/.local/share/pi-node/bin ~/.local/share/pi-node/current/bin ~/.local/share/pi-node/node-*/bin
  if test -d $d
    fish_add_path $d
  end
end
if test -x /home/linuxbrew/.linuxbrew/bin/brew
  eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
else if test -x ~/.linuxbrew/bin/brew
  eval (~/.linuxbrew/bin/brew shellenv)
end
