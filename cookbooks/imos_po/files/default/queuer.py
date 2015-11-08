#!/usr/bin/python

from tasks import handle_file
import sys

job_name = sys.argv[1]
file_path = sys.argv[2]
command = sys.argv[3]
extra_params = sys.argv[4:]

handle_file.delay(job_name, file_path, command, extra_params)
