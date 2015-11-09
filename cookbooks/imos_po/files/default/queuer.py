#!/usr/bin/python

from tasks import *
import sys

job_name = sys.argv[1]
file_path = sys.argv[2]

globals()[job_name].delay(file_path)
