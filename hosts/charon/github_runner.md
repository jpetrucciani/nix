# github_runner

This doc should contain the steps required to make an m1 mac runner for github actions. [Open this page in a browser](https://github.com/jpetrucciani/nix/settings/actions/runners/new?arch=arm64&os=osx)

```bash
dscl . -create /Users/runner
dscl . -create /Users/runner UserShell /bin/bash
dscl . -create /Users/runner RealName "runner"
dscl . -create /Users/runner UniqueID "510"
dscl . -create /Users/runner PrimaryGroupID 20
dscl . -create /Users/runner NFSHomeDirectory /Users/runner
dscl . -passwd /Users/runner password
dscl . -append /Groups/admin GroupMembership runner
```

su into `runner`:

```bash
mkdir actions-runner && cd actions-runner
curl -o actions-runner-osx-arm64-2.294.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.294.0/actions-runner-osx-arm64-2.294.0.tar.gz
echo "48ee1d58c977d6af82a5b48449a73d23ef5068e75917469d0315f32d4f4d1fef  actions-runner-osx-arm64-2.294.0.tar.gz" | shasum -a 256 -c
tar xzf ./actions-runner-osx-arm64-2.294.0.tar.gz

./config.sh  # this step requires a key from the page
./run.sh
```
