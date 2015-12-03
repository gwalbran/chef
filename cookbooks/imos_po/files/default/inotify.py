#!/usr/bin/python

import pyinotify
import os
from tasks import *
import logging

root = logging.getLogger()
root.setLevel(logging.INFO)

execfile("inotify-config.py")

def queueEvent(path, f):
    queue = watched_directories[path]
    logging.info("%s: %s" % (queue, f))
    globals()[queue].delay(f)

def listFiles(path):
    return [os.path.join(path, f) for f in os.listdir(path) if os.path.isfile(os.path.join(path, f))]

class FileEventHandler(pyinotify.ProcessEvent):
    def process_default(self, event):
        queueEvent(event.path, event.pathname)

wm = pyinotify.WatchManager()
notifier = pyinotify.Notifier(wm, FileEventHandler())

for dir in watched_directories.keys():
    for f in listFiles(dir):
        queueEvent(dir, f)

    wm.add_watch(dir, mask)

notifier.loop()
