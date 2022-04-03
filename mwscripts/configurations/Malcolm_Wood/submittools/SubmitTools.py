#!/usr/bin/python

import optparse
import fileinput
import re
import shutil
import sys
import os.path


def getJobfile(job):
    if '@' in job:
        m = re.search('(.*)@(.*)',job)
        jobnum = m.group(1)
        jobcluster = m.group(2)
        jobfile = '/mathworks/BLR/devel/bat/' + jobcluster + '/queue/' + jobnum
    else:
        jobfile = job
    return jobfile

def getRegexp():
    action_exp = '(?P<action>\w)'
    filename_exp = '(?P<filename>[^\s]*)'
    revision_exp = '(?P<revision>[\d\.]*)'
    user_exp = '(?P<user>[^\s]*)'
    full_exp = '\s*' + action_exp + '\s+' + filename_exp + '\s+' + revision_exp + '\s+.*#\s+' + user_exp + '\s*$'
    return re.compile(full_exp)


def jobfileToSubmitfile(job,submitfile):
    jobfile = getJobfile(job)
    shutil.copyfile(jobfile, submitfile)
    print 'Reading: ' + jobfile
    e = getRegexp()
    first_line = False
    for line in fileinput.input(submitfile,inplace=1):

        if not first_line:
            print '# Submit file generated from job: ' + job
            first_line = True
            """ The first line of the job file isn't useful to us """
            continue

        m = e.match(line)
        if m:
            action = m.group('action')
            if action == 's':
                line = m.group(2) + ' # ' + m.group('user') + ' ' + m.group('revision')
                print line
            elif action == 'd':
                line = '-d ' + m.group(2) + ' # ' + m.group('user') + ' ' + m.group('revision')
            elif action == 'D':
                line = '-D ' + m.group(2) + ' # ' + m.group('user')
                print line
            else:
                print'# Unexpected action: ' + line
        else:
            if line[0] == '#':
                """ comment """
            else:
                print '# ' + line
    print 'Wrote: ' + submitfile

def jobfileToRevisionList(job):
    jobfile = getJobfile(job)
    print 'Reading: ' + jobfile
    e = getRegexp()
    first_line = False
    for line in fileinput.input(jobfile):

        if not first_line:
            print '# Revision list generated from job: ' + job
            first_line = True
            """ The first line of the job file isn't useful to us """
            continue

        m = e.match(line)
        if m:
            action = m.group('action')
            if action == 's':
                line = m.group(2) + ' [' + m.group('revision') + ']'
                print line
            elif action == 'd':
                line = '-d ' + m.group(2) + ' [' + m.group('revision') + ']'
                print line
            elif action == 'D':
                line = '-D ' + m.group(2)
                print line
            else:
                print'# Unexpected action: ' + line
        else:
            if line[0] == '#':
                """ comment """
            else:
                print '# ' + line

def getMergeList(job):
  m = re.search('(.*)@(.*)',job)
  if not m:
    " Assume that we've been given a mergescript file, not a job number "
    return job
  jobnum = m.group(1)
  jobcluster = m.group(2)
  tokenfile = '/devel/' + jobcluster + '/tokens/red.' + jobnum
  if os.path.isfile(tokenfile):
    return fileinput.input(tokenfile)
  else:
    " Invoke warnaboutmerge!"
    command = "sbm warnaboutmerge -t " + jobcluster + " -j " + jobnum
    proc = os.popen(command)
    output = proc.read().split('\n')
    return output

def createMergeScript(output):
  e = re.compile('\d*\w*: (?P<file>.*): Merge required from .* to (?P<rev>.*) \(author: .*\)')
  list = '';
  for line in output:
    m = e.match(line);

    if m:
      print 'mget -r ' + m.group('rev') + ' ' + m.group('file')
      list = list + ' ' + m.group('file')

  print 'mmerge' + list

