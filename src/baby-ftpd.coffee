"use strict"
#
# # Baby FTP Deamon
#
net     = require "net"
fs      = require "fs"
path    = require "path"
exec    = require("child_process").exec
winston = require "winston"
mkdirp  = require "mkdirp"

module.exports = class BabyFtpd
  # Static variables
  @sysName = "Node_BabyFTP_Server"
  
  # fields
  authUser = {}
  logger = null
  
  constructor: (option = {})->
    logger = new winston.Logger({
      transports: [ new (winston.transports.Console)() ]
    })
    logger.setLevels winston.config.syslog.levels
    if option.logger?
      if option.logger.console is false
        logger.remove winston.transports.Console
    @fileSystem = new BabyFtpd.FileSystem(logger)
    @piServer = net.createServer()
    @piServer.fileSystem = @fileSystem
  
  addUser: (userName, userPass)->
    authUser[userName] = userPass
  
  listen: (port = 21, host = "0.0.0.0")->
    @piServer.on 'listening', ()->
      hostInfo = @address()
      logger.log "info", "Server listening on #{hostInfo.address}:#{hostInfo.port}"
    
    @piServer.on 'connection', (socket)->
      logger.log "info", "Connect from #{socket.remoteAddress}"
      socket.setTimeout(0)
      socket.setNoDelay()
      socket.dataEncoding = "binary"
      socket.passive = false
      socket.userName = null
      socket.fileSystem = @fileSystem
      socket.sessionDir = "/"
      
      # Socket response
      socket.reply = (status, message, callback)->
        message = message ? messages[status.toString()] || "No information"
        message = message.replace /\r?\n/g, "\n"
        replys = message.split("\n")
        if replys.length is 1
          replyData = status.toString() + " " + replys[0] + "\r\n"
        else
          replyData = status.toString() + "-"
          for i in [0..replys.length-1]
            if i is (replys.length - 1)
              replyData += status.toString() + " "
            else if replys[i].match(/^[0-9]/)
              replyData += "  "
            replyData += replys[i] + "\r\n"
        logger.log "debug", replyData.toString().trim()
        @write(replyData, callback)
      
      # Receive data
      socket.on 'data', (recData)->
        logger.log "debug", recData.toString().trim()
        parts    = recData.toString().trim().split(" ")
        command  = parts[0].trim().toUpperCase()
        args     = parts.slice 1, parts.length
        callable = commands[command]
        unless callable
          @reply 500, "#{command} not understood"
        else
          callable.apply socket, args
      
      # Socket closed
      socket.on 'close', ()->
        logger.log "info", "Server socket closed."
      
      # Connect approved
      socket.reply 220
    
    @piServer.listen port, host

  @changeCarriageCode: (data)->
    retData = data.replace /[\n\r]/g, "\n"
    retData = retData.replace /[\n]/g, "\r\n"
    return retData

  # Standard messages for status. (RFC 959)
  messages =
    "110": "Restart marker reply."
    "125": "Data connection already open; transfer starting."
    "150": "File status okay; about to open data connection."
    "200": "Command okay."
    "202": "Command not implemented, superfluous at this site."
    "211": "System status, or system help reply."
    "212": "Directory status."
    "213": "File status."
    "215": "NAME system type."
    "220": "Service ready for new user."
    "221": "Service closing control connection."
    "225": "Data connection open; no transfer in progress."
    "226": "Closing data connection."
    "230": "User logged in, proceed."
    "250": "Requested file action okay, completed."
    "331": "User name okay, need password."
    "332": "Need account for login."
    "350": "Requested file action pending further information."
    "421": "Service not available, closing control connection."
    "425": "Can't open data connection."
    "426": "Connection closed; transfer aborted."
    "450": "Requested file action not taken."
    "451": "Requested action aborted. Local error in processing."
    "452": "Requested action not taken."
    "500": "Syntax error, command unrecognized."
    "501": "Syntax error in parameters or arguments."
    "502": "Command not implemented."
    "503": "Bad sequence of commands."
    "504": "Command not implemented for that parameter."
    "530": "Not logged in."
    "532": "Need account for storing files."
    "550": "Requested action not taken."
    "551": "Requested action aborted. Page type unknown."
    "552": "Requested file action aborted."
    "553": "Requested action not taken."
    # 以下は個別に応答する必要あり
    "120": "Service ready in XXX minutes."
    "214": "Help message."
    "227": "Entering Passive Mode (h1,h2,h3,h4,p1,p2)."
    "257": "<PATHNAME> created."
  
  # Commands implemented by the FTP server.
  commands =
    # 未実装のもの
    "ACCT": ()->
      @reply 202
    "SMNT": ()->
      @reply 202
    "REIN": ()->
      @reply 202
    "PORT": ()->
      @reply 202
    "TYPE": ()->
      @reply 200
    "STRU": ()->
      @reply 202
    "MODE": ()->
      @reply 200
    "STOU": ()->
      @reply 202
    "APPE": ()->
      @reply 202
    "ALLO": ()->
      @reply 202
    "REST": ()->
      @reply 202
    "RNFR": ()->
      @reply 202
    "RNTO": ()->
      @reply 202
    "ABOR": ()->
      @reply 202
    "STAT": ()->
      @reply 202
    "LPRT": ()->
      @reply 202
    "LPSV": ()->
      @reply 202
    "ADAT": ()->
      @reply 202
    "AUTH": ()->
      @reply 202
    "CCC": ()->
      @reply 202
    "CONF": ()->
      @reply 202
    "ENC": ()->
      @reply 202
    "MIC": ()->
      @reply 202
    "PBSZ": ()->
      @reply 202
    "FEAT": ()->
      @reply 202
    "OPTS": ()->
      @reply 202
    "EPRT": ()->
      @reply 202
    "EPSV": ()->
      @reply 202
    "LANG": ()->
      @reply 202
    "MDTM": ()->
      @reply 202
    "MLSD": ()->
      @reply 202
    "MLST": ()->
      @reply 202
    "SIZE": ()->
      @reply 202
    
    # 各コマンドの処理
    "USER": (username)->
      @userName = username
      @reply 331
    
    "PASS": (password)->
      userPass = authUser[@userName]
      if userPass? and userPass is password
        @reply 230
      else
        @reply 530
    
    "CWD": (reqPath)->
      try
        dirPath = @fileSystem.getNewPath @sessionDir, reqPath
        checkDir = @fileSystem.checkPath dirPath
        if !checkDir.isDirectory()
          throw new Error "no directory"
        @sessionDir = dirPath
        @reply 250, "CWD command successful"
      catch err
        @reply 550, "#{reqPath}: No such directory"
    
    "CDUP": ()->
      try
        dirPath = @fileSystem.getNewPath @sessionDir, ".."
        checkDir = @fileSystem.checkPath dirPath
        if !checkDir.isDirectory()
          throw new Error "no directory"
        @sessionDir = dirPath
        @reply 200, "CDUP command successful"
      catch err
        @reply 550, "No such directory"
    
    "PWD": ()->
      @reply 257, "\"#{@sessionDir}\""
    
    "NLST": (reqPath = "")->
      @fileSystem.getNlst @sessionDir, reqPath, (err, files)=>
        if err?
          if @passive
            @dtpServer.close()
          @reply 550, "#{reqPath}: No such file or directory"
        else
          ls = BabyFtpd.changeCarriageCode files.join("\n") + "\n"
          @dtpServer.dtpSocket.sender ls
    
    "LIST": (reqPath = "")->
      @fileSystem.getList @sessionDir, reqPath, (err, stdout, stderr)=>
        if err?
          if @passive
            @dtpServer.close()
          @reply 550, "#{reqPath}: No such file or directory"
        else
          ls = BabyFtpd.changeCarriageCode stdout.replace(/^total [0-9]+$/im, "").trim()+"\n"
          @dtpServer.dtpSocket.sender ls
    
    "RETR": (reqPath)->
      @fileSystem.getFile @sessionDir, reqPath, (err, data)=>
        if err?
          if @passive
            @dtpServer.close()
          @reply 550, "#{reqPath}: No such file or directory"
        else
          @dtpServer.dtpSocket.sender data
    
    "STOR": (reqPath)->
      try
        @fileSystem.checkParentDir @sessionDir, reqPath
        if @passive
          @dtpServer.store (storeData)=>
            @fileSystem.setFile storeData, @sessionDir, reqPath, (err)=>
              if err?
                if err.message is "Disk quota exceeded"
                  @reply 552, "Transfer aborted. Disk quota exceeded"
                else
                  @reply 550
              else
                @reply 250
        else
          @reply 425
      catch err
        if @passive
          @dtpServer.close()
        return @reply 550, "#{reqPath}: No such file or directory"

    
    "DELE": (reqPath)->
      try
        delPath = @fileSystem.getNewPath @sessionDir, reqPath
        checkDir = @fileSystem.checkPath delPath
        if !checkDir.isFile()
          throw new Error "no file"
        @fileSystem.removeFile delPath, (err)=>
          if err?
              @reply 550
          else
            @reply 250, "\"#{reqPath}\" - File successfully deleted"
      catch err
        return @reply 550, "#{reqPath}: No such file or directory"
    
    "MKD": (reqPath)->
      try
        @fileSystem.checkParentDir @sessionDir, reqPath
        @fileSystem.makeDir @sessionDir, reqPath, (err)=>
          if err?
            if err.code is "EEXIST"
              @reply 550, "#{reqPath}: File exists"
            else
              @reply 550
          else
            @reply 257, "\"#{reqPath}\" - Directory successfully created"
      catch err
        return @reply 550, "#{reqPath}: No such directory"
    
    "RMD": (reqPath)->
      try
        delPath = @fileSystem.getNewPath @sessionDir, reqPath
        checkDir = @fileSystem.checkPath delPath
        if !checkDir.isDirectory()
          throw new Error "no directory"
        @fileSystem.removeDir delPath, (err)=>
          if err?
            if err.code is "ENOTEMPTY"
              @reply 550, "#{reqPath}: Directory not empty"
            else
              @reply 550
          else
            @reply 250, "\"#{reqPath}\" - Directory successfully deleted"
      catch err
        return @reply 550, "#{reqPath}: No such directory"
    
    "SYST": ()->
      @reply 215, BabyFtpd.sysName
    
    "QUIT": ()->
      @reply 221
      @end()
    
    "PASV": ()->
      @passive = true
      @dtpServer = dtpServer.call @, @
      @dtpServer.listen 0, @server.address().address
    
    "NOOP": ()->
      @reply 200
    
    "SITE": ()->
      @reply 202
      
    "HELP": ()->
      @reply 214, """
        The following commands are recognized
        USER    PASS    CWD     CDUP    QUIT    PASV    STOR
        RETR    LIST    NLST    DELE    RMD     MKD     PWD
        SYST    HELP    NOOP
        Direct comments to root
        """
  
  dtpServer = (socket)->
    dtp = net.createServer()
    dtp.storeMode = false
    dtp.storeData = []
    dtp.storeData.totalLength = 0
    dtp.storeCall = undefined
    
    dtp.store = (callback)->
      dtp.storeMode = true
      dtp.storeData = []
      dtp.storeData.totalLength = 0
      dtp.storeCall = callback
      socket.reply 125
    
    dtp.on 'listening', ()->
      dtpAddress = @address()
      logger.log "info", "Data Transfer Proccess Server listening on #{dtpAddress.address}:#{dtpAddress.port}"
      host  = dtpAddress.address.split(".").join(",")
      port1 = parseInt(dtpAddress.port / 256, 10)
      port2 = dtpAddress.port % 256
      socket.reply 227, "Entering Extended Passive Mode (#{host},#{port1},#{port2})"
    
    dtp.on "close", ()->
      logger.log "info", "Data Transfer Proccess Server closed"
      socket.passive = false
    
    dtp.on "connection", (dtpSocket)->
      @dtpSocket = dtpSocket
      logger.log "info", "DTP Connect from #{dtpSocket.remoteAddress}"
      dtpSocket.setTimeout(0)
      dtpSocket.setNoDelay()
      dtpSocket.dataEncoding = "binary"
      
      dtpSocket.on "end", ()->
        try
          socket.dtpServer.close()
        catch err
          logger.log "error", err.message
        if dtp.storeMode
          dtpSocket.storeMode = false
          data = Buffer.concat dtp.storeData, dtp.storeData.totalLength
          dtp.storeCall data
        else
          socket.reply 226
      dtpSocket.on "close", ()->
        logger.log "info", "DTP Socket closed"
      dtpSocket.on "connect", ()->
        logger.log "info", "DTP Socket connect"
      dtpSocket.on 'data', (recData)->
        dtp.storeData.push recData
        dtp.storeData.totalLength += recData.length
      dtpSocket.sender = (dataQueue)->
        socket.reply 150
        logger.log "info", "DTP Send"
        dtpSocket.end(dataQueue)
    
    dtp


class BabyFtpd.FileSystem
  logger = null
  
  constructor: (_logger)->
    @baseDir = null
    @quotaSize = 0
    logger = _logger
  
  setBase: (dirPath)->
    @baseDir = dirPath
    try
      fs.statSync @baseDir
    catch
      mkdirp.sync @baseDir
  
  setQuotaSize: (qSize)->
    @quotaSize = qSize
  
  getNewPath: (nowDir, reqPath)->
    if reqPath.indexOf("/") is 0
      retPath = reqPath
    else
      retPath = path.join nowDir, reqPath
    if retPath.length > 1 and retPath.match(/\/$/) isnt null
      retPath = retPath.replace /\/$/, ""
    retPath
  
  checkPath: (reqPath)->
    fs.statSync @baseDir+reqPath
  
  checkParentDir: (nowDir, reqPath)->
    retPath = @getNewPath nowDir, reqPath
    dirPath = path.dirname retPath
    parentDir = @checkPath dirPath
    if parentDir.isDirectory()
      return true
    else
      throw new Error "no directory"
  
  getNlst: (nowDir, reqPath, callback)->
    retPath = @getNewPath nowDir, reqPath
    fs.readdir @baseDir+retPath, callback
  
  getList: (nowDir, reqPath, callback)->
    retPath = @getNewPath nowDir, reqPath
    exec "export LANG=en_US.UTF-8; ls -l #{@baseDir}#{retPath}", callback
  
  getFile: (nowDir, reqPath, callback)->
    retPath = @getNewPath nowDir, reqPath
    fs.readFile @baseDir+retPath, callback
  
  setFile: (storeData, nowDir, reqPath, callback)->
    if @quotaSize > 0 and storeData.length > @quotaSize
      # 簡易"Disk quota exceeded"エラーシミュレーター
      logger.log "info", "Disk quota exceeded"
      callback(new Error("Disk quota exceeded"))
    else
      srorePath = @getNewPath  nowDir, reqPath
      logger.log "info", "save #{srorePath}"
      fs.writeFile @baseDir+srorePath, storeData, "binary", callback
  
  removeFile: (reqPath, callback)->
    fs.unlink @baseDir+reqPath, callback

  makeDir: (nowDir, reqPath, callback)->
    mkPath = @getNewPath  nowDir, reqPath
    fs.mkdir @baseDir+mkPath, "0755", callback

  removeDir: (reqPath, callback)->
    fs.rmdir @baseDir+reqPath, callback
