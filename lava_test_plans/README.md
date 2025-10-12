# Revolution Pi Team LAVA Test Plans

## Brief

The Revolution Pi Team provides support for testing the Kernel and distributions using this set of templates.

These LAVA templates have been extended to include LXC support and feature a modular template architecture with action templates and device-specific configurations.

This repository now includes templates designed for use with [lava-test-plans](https://github.com/Linaro/lava-test-plans), enabling the automatic generation of LAVA job definition files from templates.

## Template Architecture

The repository uses a modular template system:

- **Action templates** (`testcases/include/actions/`) - Templates for deploy, boot, test, and command actions
- **Common configuration templates** (`testcases/include/common/`) - Shared job configuration (timeouts, metadata, protocols, notifications)
- **Base workflow templates** (`testcases/include/`) - Complex templates combining multiple actions (revpi-testsuite.jinja2)
- **Device-specific testcases** - Simple configuration files that extend base templates

## Usage

First, clone the repository and navigate into it.

Then, store the path to LAVA-test-definitions in a variable:

```
git clone https://github.com/Linaro/lava-test-plans.git
cd lava-test-plans
LAVA_TESTS_PATH=PATH/TO/LAVA-test-definitions/lava_test_plans
```

### Generating LAVA Job Definitions

#### Health Check Tests

Simple health checks that verify basic device functionality:

```
python3 -m lava_test_plans \
  --device-type RevPi_Compact \
  --variables $LAVA_TESTS_PATH/variables.ini \
  --test-case health-check.yaml \
  --testcase-path $LAVA_TESTS_PATH/testcases \
  --testplan-device-path $LAVA_TESTS_PATH/devices/ \
  --verbose 1 \
  --dry-run
```

#### Nightly Test Suites

Essential test suites that run daily for continuous device validation and regression detection:

```
python3 -m lava_test_plans \
  --device-type RevPi_Compact \
  --variables $LAVA_TESTS_PATH/variables.ini \
  --test-case nightly/RevPi_Compact-000.yaml \
  --testcase-path $LAVA_TESTS_PATH/testcases \
  --template-path $LAVA_TESTS_PATH/testcases \
  --testplan-device-path $LAVA_TESTS_PATH/devices/ \
  --verbose 1 \
  --dry-run
```

### Creating New Test Cases

To create a new device-specific test case, extend the universal RevPi testsuite template:

```
{% extends "include/revpi-testsuite.jinja2" %}

{% set TAG_NR = "016" %}
{% set TPM_TEST = "tpm-2b" %}
{% set HAS_WLAN = true %}
{% set HAS_HDMI = true %}
{% set PITEST_TESTS = "pt-1 pt_test_digital_ios" %}
{% set RS485_DEVICES = ["/dev/ttyRS485"] %}
```

> [!note]
> For more information, you can use `lava-test-plans -h` or visit the repository: [lava-test-plans](https://github.com/Linaro/lava-test-plans).
