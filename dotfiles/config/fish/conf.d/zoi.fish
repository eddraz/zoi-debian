# zoi-debian: keep user tools on PATH in every foot+fish session.
fish_add_path ~/.local/bin
for d in ~/.local/share/pi-node/bin ~/.local/share/pi-node/current/bin ~/.local/share/pi-node/node-*/bin
  if test -d $d
    fish_add_path $d
  end
end
