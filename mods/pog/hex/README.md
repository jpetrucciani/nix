# hex

Hex is a nix module system that allows us to create powerful abstractions of other languages and configurations via nix! At the moment, this is the most useful for things like kubernetes specs!

---

## In this directory

### [k8s](./k8s/)

hexes related to k8s specs and charts!

### [hex.nix](./hex.nix)

hex magic module! this contains the helpers that are exposed within the `hex` attribute of the function that makes up a hex file.

### [spell.nix](./spell.nix)

this is the nix function that is actually run when you run the `hex` command
