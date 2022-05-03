#!/usr/bin/bash

cp README.md contracts/
npm publish contracts/ --access public
rm contracts/README.md
