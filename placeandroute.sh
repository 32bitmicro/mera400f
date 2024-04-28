#!/bin/bash

PROJECT=mera400f
#iCE40HX-8K Breakout Board
# iCE40HX-8K CT256 device
#- Eight user-accessible LEDs
#- 12 MHz oscillator

nextpnr-ice40 --freq 20 --hx8k --package ct256 --json $PROJECT.json --pcf-allow-unconstrained --pcf $PROJECT.pcf --asc $PROJECT.asc
icepack -s $PROJECT.asc $PROJECT.bin