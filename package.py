#!/usr/bin/python

import sys

for line in sys.stdin:
  if line.startswith('gpg-pubkey-'):
    continue # We don't care about imported keys. G'bye!
  try:
    woarch = line.rsplit('.', 1)[0] # Bye, arch!
    worel = woarch.rsplit('-', 1)[0] # Bye, release!
    wover = worel.rsplit('-', 1)[0] # Bye, version!
  except Exception, e: # Well nuts...
    print '%s ** %s' % (e, line)
    continue
  print '<package>'+wover+'</package>'
