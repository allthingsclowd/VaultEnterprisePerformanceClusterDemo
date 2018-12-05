#!/usr/bin/env bash

for x in client{1..3} consul{1..3} nomad{1..3} vault{1..3} ; do
  lxc restart ${x} --force
done
