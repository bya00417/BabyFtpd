# BabyFtpd

This ftpd is simple ftpd which operates on node.js.  
Please be created supposing using it for the test use of the system which has a ftp function, and keep in mind that it is unsuitable for employment in production environment.  

## Install

```shell
$ npm install baby-ftpd
```

## Usage

```coffee-script
BabyFtpd = require "baby-ftpd"

ftpd = new BabyFtpd
ftpd.addUser "test", "test"
ftpd.fileSystem.setBase "/var/ftp"
ftpd.listen 21, "localhost"
```
