# prepare_lava_job

prepare_lava_job is a Python script designed to generate Job files in YAML format. These job files are designed to be used with LAVA in order to automate the process of flashing and testing RevPi devices, thus saving time in identifying errors in the images.

Once the LAVA Job has been generated, it can be submitted using one of the following methods:
- lavacli command-line tool
- LAVA webUI
- LAVA REST/XML-RPC API

Please refer to the LAVA documentation for detailed instructions on how to submit the generated job. For a example using lavacli, see the "Example" section.

## Features

- Generates LAVA Job files for flashing and testing images on RevPi devices.
- Allows customization of job parameters through command-line arguments.

## Usage

The LAVA Job Generator can be executed using the following command:

- -d, --device-type: Specify the device type to use for testing.
- -u, --url: Provide the URL of the image to be flashed.
- --flash: Specify the manifest used to flash the given image onto the DUT (required).
- -s, --testsuite: Specify the job testsuite to be used after flashing (required).
- -t, --tags: Specify the tag used for selecting an appropriate device for testing.

> **_NOTE_** The default values used are taken from the Job created to flash the device. An example (and a recommendation) of a Job used for flashing devices can be found here: [../automated/deployment/job-flash-RevPi_Core.yaml](../automated/deployment/job-flash-RevPi_Core.yaml).

> **_NOTE_** By using the recommended Job:

> - the generated job is configured for a RevPi Core device (device_type: RevPi_Core) and utilizes a "configXXX" tag that corresponds to an existing device configuration in [../device-config/RevPi_Core](../device-config/RevPi_Core).

> - the image corresponds to one of our latest releases and is located under the 'deploy' section with 'namespace: recovery'."

---
> **_NOTE:_**  This behavior can be modified by providing appropriate options.
---

- A default job used to flash the image can be found here: [../automated/deployment/job-flash-RevPi_Core.yaml](../automated/deployment/job-flash-RevPi_Core.yaml)

- A testsuite with a compilation of tests for RevPi Core devices can be found here: [../plans/image-tests/RevPi_Core-004.yaml](../plans/image-tests/RevPi_Core-004.yaml)

---

For more information, please consult the LAVA documentation and the examples provided in this repository.

### Example

Example using job-flash-RevPi_Core.yaml to flash device and then running a testsuite for Core devices, saving the Job in `/tmp/job.yaml`
```
./prepare_lava_job --flash ../automated/deployment/job-flash-RevPi_Core.yaml -s ../plans/image-tests/RevPi_Core-004.yaml > /tmp/job.yaml
```

#### Submitting the Job using lavacli
```
lavacli jobs submit /tmp/job.yaml
```

### Contributing

Contributions are welcome! If you have any suggestions, bug reports, or feature requests, please create an issue in this repository.
