"use strict"
#
# # Baby FTP Deamon
#
net = require("net")

module.exports = class BabyFtpd
  authUser = {}
  constructor: (option = {})->
    @piServer = undefined
  
  addUser: (userName, userPass)->
    authUser[userName] = userPass
  
  listen: (port = 21, host = "0.0.0.0")->
    @piServer = net.createServer()
    
    @piServer.on 'listening', ()->
      hostInfo = @address()
      console.log "Server listening on #{hostInfo.address}:#{hostInfo.port}"
    
    @piServer.on 'connection', (socket)->
      console.log "Connect from #{socket.remoteAddress}"
      socket.setTimeout(0)
      socket.setNoDelay()
      socket.dataEncoding = "binary"
      socket.passive = false
      socket.userName = null
      
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
        @write(replyData, callback)
      
      # Receive data
      socket.on 'data', (recData)->
        console.log recData.toString().trim()
        parts    = recData.toString().trim().split(" ")
        command  = parts[0].trim().toUpperCase()
        args     = parts.slice 1, parts.length
        callable = commands[command]
        unless callable
          @reply 502
        else
          callable.apply socket, args
      
      # Socket closed
      socket.on 'close', ()->
        console.log "Server socket closed."
      
      # Connect approved
      socket.reply 220
    
    @piServer.listen port, host

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
    "CWD": ()->
      @reply 202
    "CDUP": ()->
      @reply 202
    "SMNT": ()->
      @reply 202
    "REIN": ()->
      @reply 202
    "PORT": ()->
      @reply 202
    "TYPE": ()->
      @reply 202
    "STRU": ()->
      @reply 202
    "MODE": ()->
      @reply 202
    "STOR": ()->
      @reply 202
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
    "DELE": ()->
      @reply 202
    "RMD": ()->
      @reply 202
    "MKD": ()->
      @reply 202
    "LIST": ()->
      @reply 202
    "SITE": ()->
      @reply 202
    "STAT": ()->
      @reply 202
    
    # 仮実装しているもの
    #"RETR": ()->
    #"PWD": ()->
    #"NLST": ()->
    
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
    
    "PWD": ()->
      @reply 257, '"/"'
    
    "NLST": ()->
      @dtpServer.dataQueue = "ABC\r\n"
      @reply 150
    
    "RETR": ()->
      @dtpServer.dataQueue = "<html></html>"
      @reply 150
    
    "SYST": ()->
      @reply 215, "Node_BabyFTP_server"
    
    "QUIT": ()->
      @reply 221
      @end()
    
    "PASV": ()->
      socket = @
      socket.passive = true
      socket.dtpServer = net.createServer()
      dtpHost = socket.server.address().address
      socket.dtpServer.dataQueue = null
      
      socket.dtpServer.on 'listening', ()->
        dtpAddress = @address()
        console.log "Data Transfer Proccess Server listening on #{dtpAddress.address}:#{dtpAddress.port}"
        host  = dtpAddress.address.split(".").join(",")
        port1 = parseInt(dtpAddress.port / 256, 10)
        port2 = dtpAddress.port % 256
        socket.reply 227, "Entering Extended Passive Mode (#{host},#{port1},#{port2})"
      
      socket.dtpServer.on "connection", (dtpSocket)->
        console.log "DTP Connect from #{dtpSocket.remoteAddress}"
        dtpSocket.setTimeout(0)
        dtpSocket.setNoDelay()
        dtpSocket.dataEncoding = "binary"
        
        dtpSocket.on "end", ()->
            socket.dtpServer.close()
            socket.reply 226
        dtpSocket.on "close", ()->
          console.log "DTP Socket closed"
        dtpSocket.on "connect", ()->
          console.log "DTP Socket connect"
        dtpSocket.on 'data', (recData)->
          console.log recData.toString().trim()
        
        dtpSocket.sender = ()->
          console.log socket.dtpServer.dataQueue
          if socket.dtpServer.dataQueue isnt null
            console.log "Send"
            clearInterval(dtpSocket.intervalId)
            dtpSocket.end(socket.dtpServer.dataQueue)
        
        dtpSocket.intervalId = setInterval(dtpSocket.sender, 100)
      
      socket.dtpServer.on "close", ()->
        console.log "Data Transfer Proccess Server closed"
        socket.passive = false
        
      socket.dtpServer.listen(0, dtpHost)
    
    "NOOP": ()->
      @reply 200
      
    "HELP": ()->
      @reply 214, """
        The following commands are recognized
        USER    PASS    PWD     NLST    RETR    SYST
        QUIT    PASV    NOOP    HELP
        Direct comments to root
        """


unless module.parent
  ftpd = new BabyFtpd
  ftpd.addUser "taka", "1234"
  ftpd.listen 8021, "localhost"
