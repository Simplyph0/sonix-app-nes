#!/usr/bin/env python3
"""Writes a tiny NES ROM that draws four tiles in a pattern, for trying the app without a game.

    python3 tools/mkrom.py test.nes

It is a few hand-assembled 6502 instructions (NROM, 16 KB of code, 8 KB of tile data): set a
palette, fill the screen with tiles 0 to 3 in turn, switch the picture on and loop. Nothing in it
belongs to anybody.
"""
import sys

code = bytearray()
labels = {}


def emit(*b):
    code.extend(b)


def here():
    return 0xC000 + len(code)


def branch(op, target_label):
    # target is resolved immediately: only backward branches are used
    off = labels[target_label] - (here() + 2)
    assert -128 <= off < 0
    emit(op, off & 0xFF)


emit(0x78)                  # SEI
emit(0xD8)                  # CLD
emit(0xA2, 0xFF)            # LDX #$FF
emit(0x9A)                  # TXS
emit(0xA9, 0x00)            # LDA #0
emit(0x8D, 0x00, 0x20)      # STA $2000
emit(0x8D, 0x01, 0x20)      # STA $2001
for n in (1, 2):            # wait for the PPU to warm up: two vertical blanks
    labels['vb%d' % n] = here()
    emit(0x2C, 0x02, 0x20)  # BIT $2002
    branch(0x10, 'vb%d' % n)  # BPL
emit(0xA9, 0x3F, 0x8D, 0x06, 0x20)   # palette address $3F00
emit(0xA9, 0x00, 0x8D, 0x06, 0x20)
emit(0xA2, 0x00)            # LDX #0
labels['pal'] = here()
pal_load = len(code)
emit(0xBD, 0x00, 0x00)      # LDA pal,X   (address patched below)
emit(0x8D, 0x07, 0x20)      # STA $2007
emit(0xE8)                  # INX
emit(0xE0, 0x04)            # CPX #4
branch(0xD0, 'pal')         # BNE
emit(0xA9, 0x20, 0x8D, 0x06, 0x20)   # name table address $2000
emit(0xA9, 0x00, 0x8D, 0x06, 0x20)
emit(0xA0, 0x04)            # LDY #4   (four pages of 256)
emit(0xA2, 0x00)            # LDX #0
labels['nt'] = here()
emit(0x8A)                  # TXA
emit(0x4A)                  # LSR A  (so that stripes are two tiles wide)
emit(0x4A)                  # LSR A
emit(0x29, 0x03)            # AND #3
emit(0x8D, 0x07, 0x20)      # STA $2007
emit(0xE8)                  # INX
branch(0xD0, 'nt')          # BNE
emit(0x88)                  # DEY
branch(0xD0, 'nt')          # BNE
emit(0xA9, 0x00, 0x8D, 0x05, 0x20)   # scroll 0, 0
emit(0x8D, 0x05, 0x20)
emit(0xA9, 0x0A, 0x8D, 0x01, 0x20)   # background on
labels['forever'] = here()
emit(0x4C, labels['forever'] & 0xFF, labels['forever'] >> 8)  # JMP forever

pal_addr = 0xC100
code[pal_load + 1] = pal_addr & 0xFF
code[pal_load + 2] = pal_addr >> 8

prg = bytearray(16384)
prg[:len(code)] = code
prg[0x100:0x104] = bytes([0x0F, 0x16, 0x2A, 0x12])   # black, red, green, blue
prg[0x3FFA:0x3FFC] = bytes([0x00, 0xC0])             # NMI
prg[0x3FFC:0x3FFE] = bytes([0x00, 0xC0])             # reset
prg[0x3FFE:0x4000] = bytes([0x00, 0xC0])             # IRQ

chr_rom = bytearray(8192)
chr_rom[16:24] = b'\xff' * 8                          # tile 1: plane 0 solid (colour 1)
chr_rom[32 + 8:32 + 16] = b'\xff' * 8                 # tile 2: plane 1 solid (colour 2)
chr_rom[48:64] = b'\xff' * 16                         # tile 3: both (colour 3)

header = bytes([0x4E, 0x45, 0x53, 0x1A, 1, 1, 0, 0]) + bytes(8)
open(sys.argv[1] if len(sys.argv) > 1 else 'test.nes', 'wb').write(header + prg + chr_rom)
