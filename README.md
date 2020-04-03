# iox-multiarch-nginx-nyancat-sample

This repository is meant to exemplify how to build an application to be executed in [Cisco IOx](https://www.cisco.com/c/en/us/products/cloud-systems-management/iox/index.html) environment on Cisco platforms having different CPU architectures (such as in this case aarch64 and x86).

## Use Case Description

Traditionally we have seen IOx applications being maintained separately per platform, by explicitly pulling the platform specific Docker Hub components, such as building for your build machine architecture (typically x86) with:

    FROM python:3.7-slim-stretch

But when cross-compiling for a different architecture such as ARM, using:

    FROM arm64v8/python:3.7-slim-stretch

You will see how to leverage [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/) experimental feature to create a web server IOx application built from Nginx for both x86 and ARM IOx platforms, using one single Dockerfile.


Describe the problem this code addresses, how your code solves the problem, challenges you had to overcome as part of the solution, and optional ideas you have in mind that could further extend your solution.

## Prerequisites

* **A build machine**, we are using Linux CentOS 8 but any flavour will do. As a matter of fact QEMU is easier to set up on Ubuntu, so go for that is you have it. We are assuming the build machine to be x86.
* Cisco **ioxclient** to be [downloaded from Cisco DevNet](https://developer.cisco.com/docs/iox/#!iox-resource-downloads).
* **Docker** with [experimental features enabled](https://docs.docker.com/engine/reference/commandline/cli/#experimental-features) and [Docker Buildx](https://docs.docker.com/buildx/working-with-buildx/) installed.
* [**QEMU**](https://www.qemu.org/) to provide ARM <-> x86 emulation layers required by the Docker Buildx builder. It may be tricky to setup QEMU properly on some Linux distributions.

One way to check if QEMU is properly installed and running is to load and execute an ARM-based container, like so:

```
[etychon@QPU-300]$ docker run -v /usr/bin/qemu-aarch64-static:/usr/bin/qemu-aarch64-static --rm -ti arm64v8/alpine '/bin/uname' '-a'
Linux bb08f6817c64 4.18.0-147.5.1.el8_1.x86_64 #1 SMP Wed Feb 5 02:00:39 UTC 2020 aarch64 Linux
```
If this runs, you're all set with QEMU. If not, something went wrong and check your configuration.

## Installation

Docker Buildx requires a builder to work, and the builder will need to know about your target CPU building architectures.

Start by creating a builder:

    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
    docker buildx rm builder
    docker buildx create --name builder --driver docker-container --use
    docker buildx inspect --bootstrap

Validate that the builder called `builder` is now the default and is configured to build on all your desired CPU architectures (in our case arm64 and amd64, amd64 being in this case the same thing as x86):

    [etychon@QPU-300]$ docker buildx ls
    NAME/NODE          DRIVER/ENDPOINT             STATUS  PLATFORMS
    builder *          docker-container                    
      builder0         unix:///var/run/docker.sock running linux/amd64, linux/arm64

It is now time to clone this repo with:

```
git clone https://github.com/etychon/iox-multiarch-nginx-nyancat-sample.git
cd iox-multiarch-nginx-nyancat-sample
```

The build command have been automated and all you need to do is:

```
sh ./build
```

The `build` script will iterate for each CPU architecture (amd64 and arm64):

* building a Docker image based on the Dockerfile and for the iterated target CPU platform. The resulting image is placed in the local Docker repository to be used by Cisco ioxclient later.
* Copy the architecture-dependent `package.yaml.$arch` to package.yaml. This will be needed by ioxclient as package.yaml tells ioxclient how to package the IOx application. The only difference between them is the CPU architecture which is `x86_64` for amd64 and `aarch64` for arm64. We could have used `sed` and do string replacement instead of a copy.
* Run ioxclient and build the IOx application based on the platform-specific Docker image, and platform-specific package.yaml. The resulting file is placed in the local directory.

After this process is completed you should have your two IOx applications ready for deployment:

```
-rw-rw-r--   1 etychon etychon 73321646 Apr  3 11:40 iox-amd64-nginx-nyancat-sample.tar.gz
-rw-rw-r--   1 etychon etychon 71784934 Apr  3 11:41 iox-arm64-nginx-nyancat-sample.tar.gz
```

Deploy, Activate and Start the IOx application for example [using Cisco IOx Local Manager](https://www.cisco.com/c/en/us/td/docs/routers/access/800/software/guides/iox/lm/reference-guide/1-9/b_iox_lm_ref_guide_1_9.html) and make sure your application port 80 (http) is accessible. This portion is outside of the scope of this documentation.

## Usage

When everything is working as expected, point your browser to your application (ip address and port you have configured) and you should see the [Nyan cat](https://en.wikipedia.org/wiki/Nyan_Cat) running like so:

![nyan](images/nyan.gif)

Show users how to use the code. Be specific.
Use appropriate formatting when showing code snippets or command line output.

----

## Credits and references

1. I have used Cristina Sturm's Nyan cat HTML5 project: https://github.com/cristurm/nyan-cat
