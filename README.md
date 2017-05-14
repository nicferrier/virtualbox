# virtualbox with limiting for images

To securely operate virtualbox in a controlled environment I would
like to be able to give people a build that only imports images that I
say are ok.

That means:

* no create image
* checking all imported images somehow are ok


I also want:

* no gui (because everyone's using vagrant)
* to allow only NAT networking (because anything else makes enterprises nervous)


This repository is my hacks on virtulabox to make that work.


### manifest scenarios

* a vm image has no manifest file - the image should be rejected
  * Ubuntu image has no manifest
* a vm image has an incorrect manifest file - the image should be rejected
  * nic-hacked.ova has a hacked manifest
* a vm image has a manifest file but the disk manifest is not in the specified store - the image should be rejected
  * lispserver.el controls that - all turned off as things stand
* a vm image has a manifest file and the disk manifest is registered - the image should be imported
  * turn on an image


### NAT networking

Seemingly this can be controlled with VboxManageAppliance.cpp where
the image is imported. If the card is not NAT we could reject it.

## to build on Linux

* [Vbox linux build instructions](https://www.virtualbox.org/wiki/Linux%20build%20instructions)
* make sure you disable hardening to do dev builds, otherwise you can't run directly from build
* builds end up in out/linux.amd64/release/bin

### helping with logging

* the RTPrintf function does a lot of logging
* some things run inside the server with no logging by default
 * you can start the server manually to see the logging, like:
 
```
out/linux.amd64/release/bin./VBoxSVC
```

generally this means running this in one terminal and what you're
doing in another.


### handling Utf8 strings

```
char *nicpsz = NULL;
RTStrAPrintf(&nicpsz, "%s", strTargetPath.c_str());
RTPrintf("import target path %s\n", nicpsz);
RTStrFree(nicpsz);
```

### running

first you need to load your modules:

```
cd out/linux.amd64/release/bin/src
make
sudo make install
sudo make load
```

then you can run:

```
cd out/linux.amd64/release/bin/src
./VBoxHeadless ...
```

and you can run the management tool:

```
cd out/linux.amd64/release/bin/src
./VBoxManage --help
```

## to build for Windows 64

OMG this is so complicated.

First get all the depends which means compiling OpenSSL at the right version.

### openssl 1.0.1

I used git to checkout `1_0_1u` of openssl.

I used
[this](https://wiki.openssl.org/index.php/Compilation_and_Installation#W64)
document which describes how to install OpenSSL from a build.

Before you do these instructions ActiveState Perl is needed. It has to
be that, MYS2 is good but uses Unix paths and doesn't build the
required Windows stuff.

Here is the instructions from that document:

* launch a Visual Studio tool x64 Cross Tools Command prompt
* change to the directory where you have copied openssl sources `cd c:\myPath\openssl`
* configure for the target OS with the command `perl Configure
VC-WIN64A`
 ** You may also be interested to set more configuration options as
 documented in the general INSTALL note (for UNIX targets). For
 instance: `perl Configure no-asm VC-WIN64A`.
* prepare the target environment with the command: `ms\do_win64a`
* ensure you start afresh and notably without linkable products from a
  previous 32bit compile (as 32 and 64 bits compiling still share
  common directories) with the command: `nmake -f ms\ntdll.mak clean`
  for the DLL target and `nmake -f ms\nt.mak clean` for static
  libraries.
* build the code with: `nmake -f ms\ntdll.mak` (respectively `nmake -f ms\nt.mak`)
* the artefacts will be found in sub directories `out32dll` and
  `out32dll.dbg` (respectively out32 and out32.dbg for static
  libraries). The libcrypto and ssl libraries are still named
  libeay32.lib and ssleay32.lib, and associated includes in inc32 !
  You may check this is true 64bit code using the Visual Studio tool
  'dumpbin'. For instance dumpbin `/headers out32dll/libeay32.lib` |
  more, and look at the FILE HEADER section.
* test the code using the various *test.exe programs in out32dll. Use
  the 'test' make target to run all tests as in `nmake -f ms\ntdll.mak test`
  * we recommend that you move/copy needed includes and libraries from the "32" directories under a new explicit directory tree for 64bit applications from where you will import and link your target applications, similar to that explained in INSTALL.W32.

After building the Windows build doesn't install anything properly so you need to:

```
mkdir /c/build/OpenSSL/lib
mkdir /c/build/OpenSSL/bin
cp out32dll/* /c/build/OpenSSL/bin
cp out32dll/* /c/build/OpenSSL/lib
cp -r include /c/build/OpenSSL/
```

### libcurl

Same deal for libcurl. Building it for what vbox expects is a hard problem.

I found
[this](https://github.com/blackrosezy/build-libcurl-windows/blob/master/build.bat)
and followed it and it seems to work ok.

### modified build sequence

Apparently the build sequence on Windows is just plain wrong in the docs you find online.

I've got this:

```
C:> kBuild\envwin.cmd --win64
C:> cscript configure.vbs  \
    --with-mingw-w64=\sandbox\work\mingw64 \
    --with-openssl=\sandbox\work\OpenSSL \
    --with-libcurl=\sandbox\work\curl\lib \
    --with-VC="\Program Files (x86)\Microsoft Visual Studio 10.0\VC"
C:> kmk
```

I'm currently getting a build failure because of Python though. I do
not want Python so I don't see why that is.

Note: the env.bat seems to be not required and confuses the 64 bit
build if it is used.

## importing OVF's

some useful stuff here:

```
cd out/linux.amd64/release/bin/src
./VBoxManage import -n ~/Downloads/Ubuntu=13.ovf
```

will fail because of eula but the output should show you how to get round it:

```

8: End-user license agreement
    (display with "--vsys 0 --eula show";
    accept with "--vsys 0 --eula accept")
```


## OVAs and signing

If you export an OVA with a manifest file, like so:

```
VBoxManage export 1bcef521-9ba6-4c31-aef9-1bf12f3e6b06 -o ~/Downloads/nic.ova --options manifest
```

then you get a manifest file with signatures embedded in the OVA.

Use tar to see inside the OVA:

```
$ tar tvf nic.ova
-rw------- someone/someone 8515 2017-02-15 22:35 nic.ovf
-rw------- someone/someone 1219005952 2017-02-15 22:37 nic-disk1.vmdk
-rw------- someone/someone        121 2017-02-15 22:37 nic.mf
```

You can extract as well, with tar, and check the contents of the mf file:

```
$ tar xvf nic.ova
nic.ovf
nic-disk1.vmdk
nic.mf
$ cat nic.mf 
SHA1 (nic.ovf)= aa6357bfa1c4b689daf5cc07114023093df2f286
SHA1 (nic-disk1.vmdk)= 6acdc7562db5c999a2e7fb8b7cfb1c96de1e8825
$ sha1sum nic-disk1.vmdk 
6acdc7562db5c999a2e7fb8b7cfb1c96de1e8825  nic-disk1.vmdk
```

as you can see, it all works out. The disk has a sha which we can test deliberately.



## how the digest is compared

ApplianceImportImpl.cpp/i_verifyManifestFile

calls manifest2.cpp/RTManifestEqualsEx

calls manifest2.cpp/RTStrSpaceEnumerate with rtManifestEntryCompare

manifest2.cpp/rtManifestEntryCompare calls RTStrSpaceEnumerate with rtManifestAttributeCompare

manifest2.cpp/rtManifestAttributeCompare does the attribute comparison with the digests
