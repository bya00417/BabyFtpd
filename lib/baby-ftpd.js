"use strict";
var BabyFtpd, exec, fs, net;

net = require("net");

fs = require("fs");

exec = require("child_process").exec;

module.exports = BabyFtpd = (function() {
  var authUser, commands, dtpServer, messages;

  BabyFtpd.sysName = "Node_BabyFTP_Server";

  authUser = {};

  function BabyFtpd(option) {
    if (option == null) {
      option = {};
    }
    this.fileSystem = new BabyFtpd.FileSystem();
    this.piServer = net.createServer();
    this.piServer.fileSystem = this.fileSystem;
  }

  BabyFtpd.prototype.addUser = function(userName, userPass) {
    return authUser[userName] = userPass;
  };

  BabyFtpd.prototype.listen = function(port, host) {
    if (port == null) {
      port = 21;
    }
    if (host == null) {
      host = "0.0.0.0";
    }
    this.piServer.on('listening', function() {
      var hostInfo;
      hostInfo = this.address();
      return console.log("Server listening on " + hostInfo.address + ":" + hostInfo.port);
    });
    this.piServer.on('connection', function(socket) {
      console.log("Connect from " + socket.remoteAddress);
      socket.setTimeout(0);
      socket.setNoDelay();
      socket.dataEncoding = "binary";
      socket.passive = false;
      socket.userName = null;
      socket.fileSystem = this.fileSystem;
      socket.sessionDir = "/";
      socket.reply = function(status, message, callback) {
        var i, replyData, replys, _i, _ref;
        message = (message != null ? message : messages[status.toString()]) || "No information";
        message = message.replace(/\r?\n/g, "\n");
        replys = message.split("\n");
        if (replys.length === 1) {
          replyData = status.toString() + " " + replys[0] + "\r\n";
        } else {
          replyData = status.toString() + "-";
          for (i = _i = 0, _ref = replys.length - 1; 0 <= _ref ? _i <= _ref : _i >= _ref; i = 0 <= _ref ? ++_i : --_i) {
            if (i === (replys.length - 1)) {
              replyData += status.toString() + " ";
            } else if (replys[i].match(/^[0-9]/)) {
              replyData += "  ";
            }
            replyData += replys[i] + "\r\n";
          }
        }
        return this.write(replyData, callback);
      };
      socket.on('data', function(recData) {
        var args, callable, command, parts;
        console.log(recData.toString().trim());
        parts = recData.toString().trim().split(" ");
        command = parts[0].trim().toUpperCase();
        args = parts.slice(1, parts.length);
        callable = commands[command];
        if (!callable) {
          return this.reply(500, "" + command + " not understood");
        } else {
          return callable.apply(socket, args);
        }
      });
      socket.on('close', function() {
        return console.log("Server socket closed.");
      });
      return socket.reply(220);
    });
    return this.piServer.listen(port, host);
  };

  messages = {
    "110": "Restart marker reply.",
    "125": "Data connection already open; transfer starting.",
    "150": "File status okay; about to open data connection.",
    "200": "Command okay.",
    "202": "Command not implemented, superfluous at this site.",
    "211": "System status, or system help reply.",
    "212": "Directory status.",
    "213": "File status.",
    "215": "NAME system type.",
    "220": "Service ready for new user.",
    "221": "Service closing control connection.",
    "225": "Data connection open; no transfer in progress.",
    "226": "Closing data connection.",
    "230": "User logged in, proceed.",
    "250": "Requested file action okay, completed.",
    "331": "User name okay, need password.",
    "332": "Need account for login.",
    "350": "Requested file action pending further information.",
    "421": "Service not available, closing control connection.",
    "425": "Can't open data connection.",
    "426": "Connection closed; transfer aborted.",
    "450": "Requested file action not taken.",
    "451": "Requested action aborted. Local error in processing.",
    "452": "Requested action not taken.",
    "500": "Syntax error, command unrecognized.",
    "501": "Syntax error in parameters or arguments.",
    "502": "Command not implemented.",
    "503": "Bad sequence of commands.",
    "504": "Command not implemented for that parameter.",
    "530": "Not logged in.",
    "532": "Need account for storing files.",
    "550": "Requested action not taken.",
    "551": "Requested action aborted. Page type unknown.",
    "552": "Requested file action aborted.",
    "553": "Requested action not taken.",
    "120": "Service ready in XXX minutes.",
    "214": "Help message.",
    "227": "Entering Passive Mode (h1,h2,h3,h4,p1,p2).",
    "257": "<PATHNAME> created."
  };

  commands = {
    "ACCT": function() {
      return this.reply(202);
    },
    "SMNT": function() {
      return this.reply(202);
    },
    "REIN": function() {
      return this.reply(202);
    },
    "PORT": function() {
      return this.reply(202);
    },
    "TYPE": function() {
      return this.reply(200);
    },
    "STRU": function() {
      return this.reply(202);
    },
    "MODE": function() {
      return this.reply(200);
    },
    "STOU": function() {
      return this.reply(202);
    },
    "APPE": function() {
      return this.reply(202);
    },
    "ALLO": function() {
      return this.reply(202);
    },
    "REST": function() {
      return this.reply(202);
    },
    "RNFR": function() {
      return this.reply(202);
    },
    "RNTO": function() {
      return this.reply(202);
    },
    "ABOR": function() {
      return this.reply(202);
    },
    "DELE": function() {
      return this.reply(202);
    },
    "STAT": function() {
      return this.reply(202);
    },
    "LPRT": function() {
      return this.reply(202);
    },
    "LPSV": function() {
      return this.reply(202);
    },
    "ADAT": function() {
      return this.reply(202);
    },
    "AUTH": function() {
      return this.reply(202);
    },
    "CCC": function() {
      return this.reply(202);
    },
    "CONF": function() {
      return this.reply(202);
    },
    "ENC": function() {
      return this.reply(202);
    },
    "MIC": function() {
      return this.reply(202);
    },
    "PBSZ": function() {
      return this.reply(202);
    },
    "FEAT": function() {
      return this.reply(202);
    },
    "OPTS": function() {
      return this.reply(202);
    },
    "EPRT": function() {
      return this.reply(202);
    },
    "EPSV": function() {
      return this.reply(202);
    },
    "LANG": function() {
      return this.reply(202);
    },
    "MDTM": function() {
      return this.reply(202);
    },
    "MLSD": function() {
      return this.reply(202);
    },
    "MLST": function() {
      return this.reply(202);
    },
    "SIZE": function() {
      return this.reply(202);
    },
    "USER": function(username) {
      this.userName = username;
      return this.reply(331);
    },
    "PASS": function(password) {
      var userPass;
      userPass = authUser[this.userName];
      if ((userPass != null) && userPass === password) {
        return this.reply(230);
      } else {
        return this.reply(530);
      }
    },
    "CWD": function(reqPath) {
      var err;
      try {
        this.sessionDir = this.fileSystem.getNewPath(this.sessionDir, reqPath, true);
        return this.reply(250, "CWD command successful");
      } catch (_error) {
        err = _error;
        return this.reply(550, "" + reqPath + ": No such directory");
      }
    },
    "CDUP": function() {
      var err;
      try {
        this.sessionDir = this.fileSystem.getNewPath(this.sessionDir, "..", true);
        return this.reply(200, "CDUP command successful");
      } catch (_error) {
        err = _error;
        return this.reply(550, "No such directory");
      }
    },
    "PWD": function() {
      return this.reply(257, "\"" + this.sessionDir + "\"");
    },
    "NLST": function(reqPath) {
      if (reqPath == null) {
        reqPath = "";
      }
      return this.fileSystem.getNlst(this.sessionDir, reqPath, (function(_this) {
        return function(err, files) {
          if (err != null) {
            if (_this.passive) {
              _this.dtpServer.close();
            }
            return _this.reply(550, "" + reqPath + ": No such file or directory");
          } else {
            return _this.dtpServer.dtpSocket.sender(files.join("\r\n") + "\r\n");
          }
        };
      })(this));
    },
    "LIST": function(reqPath) {
      if (reqPath == null) {
        reqPath = "";
      }
      return this.fileSystem.getList(this.sessionDir, reqPath, (function(_this) {
        return function(err, stdout, stderr) {
          if (err != null) {
            if (_this.passive) {
              _this.dtpServer.close();
            }
            return _this.reply(550, "" + reqPath + ": No such file or directory");
          } else {
            return _this.dtpServer.dtpSocket.sender(stdout.replace(/^total [0-9]+$/im, "").trim());
          }
        };
      })(this));
    },
    "RETR": function(reqPath) {
      return this.fileSystem.getFile(this.sessionDir, reqPath, (function(_this) {
        return function(err, data) {
          if (err != null) {
            if (_this.passive) {
              _this.dtpServer.close();
            }
            return _this.reply(550, "" + reqPath + ": No such file or directory");
          } else {
            return _this.dtpServer.dtpSocket.sender(data);
          }
        };
      })(this));
    },
    "STOR": function(reqPath) {
      var dirPath, err, fileName, retPath, splitPath, srorePath;
      if (reqPath.indexOf("/") >= 0) {
        splitPath = reqPath.split("/");
        fileName = splitPath.pop();
        dirPath = splitPath.join("/");
        try {
          retPath = this.fileSystem.getNewPath(this.sessionDir, dirPath, true);
          srorePath = retPath + "/" + fileName;
        } catch (_error) {
          err = _error;
          if (this.passive) {
            this.dtpServer.close();
          }
          return this.reply(550, "" + reqPath + ": No such file or directory");
        }
      } else {
        if (this.sessionDir === "/") {
          srorePath = "/" + reqPath;
        } else {
          srorePath = this.sessionDir + "/" + reqPath;
        }
      }
      return this.dtpServer.store((function(_this) {
        return function(storeData) {
          return _this.fileSystem.setFile(storeData, srorePath, function(err) {
            if (err != null) {
              return _this.reply(550);
            } else {
              return _this.reply(250);
            }
          });
        };
      })(this));
    },
    "MKD": function(reqPath) {
      var dirPath, err, mkDirName, mkPath, retPath, splitPath;
      if (reqPath.indexOf("/") >= 0) {
        splitPath = reqPath.split("/");
        mkDirName = splitPath.pop();
        dirPath = splitPath.join("/");
        try {
          retPath = this.fileSystem.getNewPath(this.sessionDir, dirPath, true);
          mkPath = retPath + "/" + mkDirName;
        } catch (_error) {
          err = _error;
          return this.reply(550, "" + reqPath + ": No such directory");
        }
      } else {
        if (this.sessionDir === "/") {
          mkPath = "/" + reqPath;
        } else {
          mkPath = this.sessionDir + "/" + reqPath;
        }
      }
      return this.fileSystem.makeDir(mkPath, (function(_this) {
        return function(err) {
          if (err != null) {
            if (err.code === "EEXIST") {
              return _this.reply(550, "" + reqPath + ": File exists");
            } else {
              return _this.reply(550);
            }
          } else {
            return _this.reply(257, "\"" + reqPath + "\" - Directory successfully created");
          }
        };
      })(this));
    },
    "RMD": function(reqPath) {
      var delPath, err;
      try {
        delPath = this.fileSystem.getNewPath(this.sessionDir, reqPath, true);
        return this.reply(202);
      } catch (_error) {
        err = _error;
        return this.reply(550, "" + reqPath + ": No such directory");
      }
    },
    "SYST": function() {
      return this.reply(215, BabyFtpd.sysName);
    },
    "QUIT": function() {
      this.reply(221);
      return this.end();
    },
    "PASV": function() {
      this.passive = true;
      this.dtpServer = dtpServer.call(this, this);
      return this.dtpServer.listen(0, this.server.address().address);
    },
    "NOOP": function() {
      return this.reply(200);
    },
    "SITE": function() {
      return this.reply(202);
    },
    "HELP": function() {
      return this.reply(214, "The following commands are recognized\nUSER    PASS    PWD     NLST    LIST    RETR    SYST\nCWD     CDUP    MKD     QUIT    PASV    NOOP    HELP\nDirect comments to root");
    }
  };

  dtpServer = function(socket) {
    var dtp;
    dtp = net.createServer();
    dtp.storeMode = false;
    dtp.storeData = [];
    dtp.storeData.totalLength = 0;
    dtp.storeCall = void 0;
    dtp.store = function(callback) {
      dtp.storeMode = true;
      dtp.storeData = [];
      dtp.storeData.totalLength = 0;
      dtp.storeCall = callback;
      return socket.reply(125);
    };
    dtp.on('listening', function() {
      var dtpAddress, host, port1, port2;
      dtpAddress = this.address();
      console.log("Data Transfer Proccess Server listening on " + dtpAddress.address + ":" + dtpAddress.port);
      host = dtpAddress.address.split(".").join(",");
      port1 = parseInt(dtpAddress.port / 256, 10);
      port2 = dtpAddress.port % 256;
      return socket.reply(227, "Entering Extended Passive Mode (" + host + "," + port1 + "," + port2 + ")");
    });
    dtp.on("close", function() {
      console.log("Data Transfer Proccess Server closed");
      return socket.passive = false;
    });
    dtp.on("connection", function(dtpSocket) {
      this.dtpSocket = dtpSocket;
      console.log("DTP Connect from " + dtpSocket.remoteAddress);
      dtpSocket.setTimeout(0);
      dtpSocket.setNoDelay();
      dtpSocket.dataEncoding = "binary";
      dtpSocket.on("end", function() {
        var data;
        socket.dtpServer.close();
        if (dtp.storeMode) {
          dtpSocket.storeMode = false;
          data = Buffer.concat(dtp.storeData, dtp.storeData.totalLength);
          return dtp.storeCall(data);
        } else {
          return socket.reply(226);
        }
      });
      dtpSocket.on("close", function() {
        return console.log("DTP Socket closed");
      });
      dtpSocket.on("connect", function() {
        return console.log("DTP Socket connect");
      });
      dtpSocket.on('data', function(recData) {
        dtp.storeData.push(recData);
        return dtp.storeData.totalLength += recData.length;
      });
      return dtpSocket.sender = function(dataQueue) {
        socket.reply(150);
        console.log("DTP Send");
        return dtpSocket.end(dataQueue);
      };
    });
    return dtp;
  };

  return BabyFtpd;

})();

BabyFtpd.FileSystem = (function() {
  function FileSystem() {
    this.baseDir = null;
  }

  FileSystem.prototype.setBase = function(dirPath) {
    return this.baseDir = dirPath;
  };

  FileSystem.prototype.getNewPath = function(nowDir, reqPath, isDir) {
    var pathStats, retPath, tmpDir;
    if (isDir == null) {
      isDir = false;
    }
    if (reqPath.indexOf("/") === 0) {
      retPath = reqPath;
    } else {
      tmpDir = nowDir.split("/");
      reqPath.split("/").map(function(aPath) {
        if (aPath === "..") {
          tmpDir.pop();
          if (tmpDir.length === 1) {
            return tmpDir.push("");
          }
        } else if (aPath === ".") {
          return null;
        } else {
          if (tmpDir.length === 2 && tmpDir[1] === "") {
            tmpDir.pop();
          }
          return tmpDir.push(aPath);
        }
      });
      retPath = tmpDir.join("/");
    }
    if (retPath.length > 1 && retPath.match(/\/$/) !== null) {
      retPath = retPath.replace(/\/$/, "");
    }
    pathStats = fs.statSync(this.baseDir + retPath);
    if (!isDir || pathStats.isDirectory()) {
      return retPath;
    } else {
      throw new Error("no directory");
    }
  };

  FileSystem.prototype.getNlst = function(nowDir, reqPath, callback) {
    var err, retPath;
    try {
      retPath = this.getNewPath(nowDir, reqPath);
      return fs.readdir(this.baseDir + retPath, callback);
    } catch (_error) {
      err = _error;
      return callback(err);
    }
  };

  FileSystem.prototype.getList = function(nowDir, reqPath, callback) {
    var err, retPath;
    try {
      retPath = this.getNewPath(nowDir, reqPath);
      return exec("export LANG=en_US.UTF-8; ls -l " + this.baseDir + retPath, callback);
    } catch (_error) {
      err = _error;
      return callback(err);
    }
  };

  FileSystem.prototype.getFile = function(nowDir, reqPath, callback) {
    var err, retPath;
    try {
      retPath = this.getNewPath(nowDir, reqPath);
      return fs.readFile(this.baseDir + retPath, callback);
    } catch (_error) {
      err = _error;
      return callback(err);
    }
  };

  FileSystem.prototype.setFile = function(storeData, srorePath, callback) {
    console.log("save " + srorePath);
    return fs.writeFile(this.baseDir + srorePath, storeData, "binary", callback);
  };

  FileSystem.prototype.makeDir = function(reqPath, callback) {
    return fs.mkdir(this.baseDir + reqPath, "0755", callback);
  };

  return FileSystem;

})();
