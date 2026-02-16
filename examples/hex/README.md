# hex

Examples of some hex files for configuring things on a [kubernetes](https://kubernetes.io/) cluster.

## usage

hex is comprised of two tools:

- `hexcast`: the tool for casting nix code into yaml/json/etc. This script takes a single nix file as an argument, and outputs `yaml` or `json`.
- `hex`: the tool that uses hexcast under the hood to render and diff/apply those files against a [kubernetes](https://kubernetes.io/) cluster

both of these tools are created with [pog](https://github.com/jpetrucciani/pog), so they have nice bash completion, smart flags, etc. Use the `--help` flag with either to see what options they currently support!

hex tries to implement a plan and apply workflow with the given specs, similar to how [terraform](https://developer.hashicorp.com/terraform) does things with infrastructure.

## caveat emptor!

there are some tradeoffs when doing things with hex!

hex does not track the expected state between applies (like terraform does with a state file or state store). This means that hex is not able to detect things that need to be deleted (yet)!

### basic workflow

```bash
# hex by default will use a file named specs.nix
hex

# you can also target a specific file with `-t`
hex -t charts.nix

# running these will trigger a render, then will diff against the live state of the cluster!
```

---

## In this directory

### [charts.nix](./charts.nix)

an example of how to use included helm charts in hex! you can find the current list of hex modules in the [hex repo](https://github.com/jpetrucciani/hex)

### [default.nix](./default.nix)

this is a lightweight nix env showing how you can include hex in your local environment
