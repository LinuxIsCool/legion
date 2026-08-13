#!/usr/bin/env python3
import socket, sys
s = socket.socket(socket.AF_UNIX)
s.connect("/tmp/hypr-alttab.sock")
s.send(sys.argv[1].encode())
s.close()
