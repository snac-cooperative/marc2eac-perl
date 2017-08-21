#!/bin/bash
# Note hard coded location of the jar file.
export CLASSPATH=/home/twl8n/bin/saxon9he.jar:$CLASSPATH
java net.sf.saxon.Transform ${1+"$@"}
