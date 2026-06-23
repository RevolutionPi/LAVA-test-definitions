# How to run tests with test-runner

This guide explains how to run existing tests from this repository using the
`test-runner` tool.

## Prerequisites

- Python 3 installed
- SSH access to the target RevPi device (passwordless, see below)
- This repository cloned somewhere on your machine or on the device

## Setup

### 1. Clone the repository

```sh
git clone https://gitlab.com/revolutionpi/infrastructure/testing/LAVA-test-definitions.git
cd LAVA-test-definitions
```

### 2. Create and activate a Python virtual environment

```sh
echo venv >> "$(git rev-parse --git-path info/exclude)"
python3 -m venv venv
. venv/bin/activate
pip install -r automated/utils/requirements.txt
```

You only need to do this once. On subsequent sessions, just activate the venv:

```sh
. venv/bin/activate
```

### 3. Load the environment

Always run this from the **root of the repository** before using `test-runner`:

```sh
. ./automated/bin/setenv.sh
```

This sets `REPO_PATH` and adds `automated/bin/` to your `PATH` so you can call
`test-runner` directly.

---

## Running a test

A test is defined by a YAML file (called a *test definition*) that lives under
`automated/`. For example:

```
automated/revpi/pibridge/pibridge-error.yaml
```

### Scenario A: Running on the device itself (SSH in first)

This is the simplest approach. You SSH into the RevPi, run the full setup there,
and execute the test locally.

```sh
ssh root@<device-ip>
cd ~/dev/LAVA-test-definitions    # wherever you cloned the repo on the device
. venv/bin/activate
. ./automated/bin/setenv.sh
test-runner -esd automated/revpi/pibridge/pibridge-error.yaml
```

The flags used here:

| Flag | Meaning |
|------|---------|
| `-d <path>` | Path to the test definition YAML (relative to repo root) |
| `-s` | Skip install. Don't install packages before the test |
| `-e` | Skip environment. Don't collect board/distro metadata |

### Scenario B: Running from your PC, targeting the device remotely

The repo stays on your PC. `test-runner` copies the files to the device over
SSH and runs the test there. The device IP is passed with `-g`.

```sh
# On your PC, from the repo root
. venv/bin/activate
. ./automated/bin/setenv.sh
test-runner -esd automated/revpi/pibridge/pibridge-error.yaml -g root@<device-ip>
```

**Requirement:** SSH authentication to the root user must be passwordless (key-based).

On RevPi devices the root account has no password set, so `ssh-copy-id`
cannot be used directly. One way to get your key onto root is to first copy
it to the `pi` user and then manually move it over:

```sh
ssh-copy-id pi@<device-ip>
```

Then log into the device and run:

```sh
sudo -i
mkdir -p /root/.ssh
cat /home/pi/.ssh/authorized_keys >> /root/.ssh/authorized_keys
```

Using `>>` appends to the file without overwriting any existing keys.

### Passing parameters to a test

Some tests accept parameters (listed under `params:` in the YAML). Pass them
with `-r`:

```sh
test-runner -esd automated/revpi/pibridge/pibridge-error.yaml \
    -r SKIP_INSTALL=false TESTS=pibridge-error
```

Multiple parameters are separated by spaces after `-r`.

---

## Understanding the output

### During the run

The test runner prints each step as it executes them:

```
+ cd ./automated/revpi/pibridge
+ ./pibridge-error.sh -s True -t pibridge-error
INFO: Running pibridge-error test...
pibridge-error pass
pibridge-error-rx-err-metric pass 0 packets
```

Each test case reports `pass`, `fail`, or `skip`. Tests that measure something
also report a value and unit.

### After the run

Results are saved to `$HOME/output/<test-name>_<uuid>/`. The most useful files:

| File | Content |
|------|---------|
| `result.csv` | All results in a table: name, test_case_id, result, measurement, units |
| `result.json` | Same results in JSON format |
| `stdout.log` | Full output of the test execution |

Example `result.csv`:

```
name,test_case_id,result,measurement,units,test_params
pibridge-error,pibridge-error,pass,,,SKIP_INSTALL=false;TESTS=pibridge-error
pibridge-error,pibridge-error-rx-err-metric,pass,0.0,packets,SKIP_INSTALL=false;TESTS=pibridge-error
pibridge-error,pibridge-error-tx-err-metric,pass,0.0,packets,SKIP_INSTALL=false;TESTS=pibridge-error
```

A test passes when `result` is `pass`. If a measurement is present, it means
the test also reported a numeric metric (e.g. packet counts, timing).

---
