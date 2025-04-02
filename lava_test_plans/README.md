# Revolution Pi Team LAVA Test Plans

## Brief

The Revolution Pi Team provides support for testing the Kernel and distributions using this set of templates.

These LAVA templates have been extended to include LXC support.

This repository now includes templates designed for use with [lava-test-plans](https://github.com/Linaro/lava-test-plans), enabling the automatic generation of LAVA job definition files from templates.

## Usage

First, clone the repository and navigate into it.

Then, store the path to LAVA-test-definitions in a variable:

```
git clone https://github.com/Linaro/lava-test-plans.git
cd lava-test-plans
LAVA_TESTS_PATH=PATH/TO/LAVA-test-definitions/lava_test_plans
```


### Generating LAVA Job Definitions Manually

To manually generate example LAVA jobs, here is one example:

### RevPi Devices Health Check for RevPi Compact

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

> [!note]
> For more information, you can use `lava-test-plans -h` or visit the repository: [lava-test-plans](https://github.com/Linaro/lava-test-plans).
