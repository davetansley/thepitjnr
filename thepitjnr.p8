pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
-- The Pit Jnr
-- by Dave Tansley
#include /thepitjnr/main.lua

__gfx__
000f0000000f00000000f0000000f000000f00000000f0000f000000000000f000000000f88aa0f0f00f00f00f00f00f022200f00f0022200000000000000000
00fff00000fff000000fff00000fff0000fff00ff00fff00fff0000000000fff00000000f08aaffff0fff0f00f0fff0f02720ffffff027200000000000000000
000f0000000f00000000f0000000f000f00f00a00a00f00f0f000000000000f000000000008aa0f00a0f0a0000a0f0f0022200f00f0022200000000000000000
00aaa88800aaa888888aaa00888aaa00faaaaa0000aaaaafaaa8800000088aaa000800f00f8a80000aaaa000000aaaa002200aaaaaa002200000000000000000
00aaaa0000aaaa0000aaaa0000aaaa0000aaa000000aaa00aaaa00000000aaaa0008a8f00f00800000aaa000000aaa0002288aaaaaa882200000000000000000
008880000088880000088800008888000088880ff088880088880000000088880f0aa80000000000088880000008888002000888888000200000000000000000
0f80800000800ff0000808f00ff00800f800008ff800008f800ff000000ff008fffaa80f00000000080008000080008022208008800802220000000000000000
0f00ff0000ff000000ff00f00000ff00f00000000000000fff000000000000ff0f0aa88f00000000ff0000ffff0000ff200ff0ffff0ff0020000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
cccccccc111111111111111cc1111111bbbbbbbb88888888a0a0a0a00088880008888880800aa008800aa0080077700000777000007770008888888800000000
cccccccc11111111111111cccc111111bbbbbbbb888888880a0a0a0a0888888088888888880aa088880aa08807a7c7000767a70007c767008888888800000000
cccccccc1111111111111cccccc11111bbbbbbbb00000000a0a0a0a08888888808888888088aa880088aa8807aa7cc707667aa707cc766708888888800000000
cccccccc111111111111cccccccc1111bbbbbbbb000000000a0a0a0a0888888808888888008aa800008aa8000aa7cc000667aa000cc766008888888800000000
cccccccc11111111111cccccccccc111bbbbbbbb00000000a0a0a0a08888888088888880eeeeeeee8888888800a7c0000067a00000c760008888888800000000
cccccccc1111111111cccccccccccc11bbbbbbbb000000000a0a0a0a88888880888888880eeeeee0088888800007000000070000000700008888888800000000
cccccccc111111111cccccccccccccc1bbbbbbbb00000000a0a0a0a0888888880888888000eeee00008888000000000000000000000000008888888800000000
cccccccc11111111ccccccccccccccccbbbbbbbb000000000a0a0a0a0888888000888800000ee000000880000000000000000000000000008888888800000000
88888888888008888888888008888888888008888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888008888888888008888888888008888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
88888888888888888880000008888888888808888888008800000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800888888888888888000008880888888888888008800000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800888888888888888000008880888088888888888800000000000000000000000000000000000000000000000000000000000000000000000000000000
00888800888008888880000008888880888008888888888800c7c70000caca00007c7c0000000000000000000000000000000000000000000000000000000000
0088880088800888888888800888888088800888888088800c7c7c700cacaca007c7c7c000000000000000000000000000000000000000000000000000000000
00888800888008888888888008888880888008888880888000c7c70000caca00007c7c0000000000000000000000000000000000000000000000000000000000
00000aacc88000000000088ccaa00000000000088888800000000008888880000000000000000000000000000000000000000000000000000000000000000000
000cccccccccc000000cccccccccc0008888888aaaaaa8808888888aaaaaa8800000000000000000000000000000000000000000000000000000000000000000
cccccccccccccccccccccccccccccccc000008811111188000000881111118800000000000000000000000000000000000000000000000000000000000000000
8a88a888a888a88aa88a888a888a88a8000000888888800000000088888880000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa088888888888888008888888888888800000000000000000000000000000000000000000000000000000000000000000
00aaaaaaaaaaaa0000aaaaaaaaaaaa008a1a1a1a1a1a1a188aaaaaaaaaaaaaa80000000000000000000000000000000000000000000000000000000000000000
008aaaaaaaaaa800008aaaaaaaaaa8008aaaaaaaaaaaaaa881a1a1a1a1a1a1a80000000000000000000000000000000000000000000000000000000000000000
0cc00008c0000cc00cc0000c80000cc0088888888888888008888888888888800000000000000000000000000000000000000000000000000000000000000000
__label__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000770077007707770777000007770777077707770000000000000000000000000000000000007070777007707070000077707770777077700000000
00000000007000700070707070700000007070707070707070000000000000000000000000000000000007070070070007070000070707070707070700000000
00000000007770700070707700770000007070707070707070000000000000000000000000000000000007770070070007770000077707770777077700000000
00000000000070700070707070700000007070707070707070000000000000000000000000000000000007070070070707070000000700070007000700000000
00000000007700077077007070777000007770777077707770000000000000000000000000000000000007070777077707070000000700070007000700000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
11111111111111111111111111111111111111111111111111111111111111cccc11111111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111111cccccc1111111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111111cccccccc111111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111111cccccccccc11111111111111111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111111111111111cccccccccccc1111111111111111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111111111111111cccccccccccccc111111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111111111111cccccccccccccccc11111111111111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111111cccccccccccccccccccccccccccccccccc11111111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111111cccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111111
111111111111111111111111111111111111111111111cccccccccccccccccccccccccccccccccccccc111111111111111111111111111111111111111111111
11111111111111111111111111111111111111111111cccccccccccccccccccccccccccccccccccccccc11111111111111111111111111111111111111111111
1111111111111111111111111111111111111111111cccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111111
111111111111111111111111111111111111111111cccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111111111111111111
11111111111111111111111111111111111111111cccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111111111111111111
1111111111111111111111111111111111111111cccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111111
cccccccccccccccc000f0000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111111111111111
cccccccccccccccc00fff000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111111111111111
cccccccccccccccc000f0000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111111
cccccccccccccccc00aaa888cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111111111111
cccccccccccccccc00aaaa00ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111111111111
cccccccccccccccc00888000cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111111111
cccccccccccccccc0f808000ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111111111
cccccccccccccccc0f00ff00cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111111111
cccccccca0a0a0a000000000a0a0a0a000888800cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccccc
cccccccc0a0a0a0a000000000a0a0a0a08888880cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccccc
cccccccca0a0a0a000000000a0a0a0a088888888cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccccc
cccccccc0a0a0a0a000000000a0a0a0a08888888cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccccc
cccccccca0a0a0a000000000a0a0a0a088888880cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccccc
cccccccc0a0a0a0a000000000a0a0a0a88888880cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccccc
cccccccca0a0a0a000000000a0a0a0a088888888cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccccc
cccccccc0a0a0a0a000000000a0a0a0a08888880cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc00000000cccccccc
cccccccca0a0a0a00000000000000000a0a0a0a0a0a0a0a0cccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccc0a0a0a0a00000000000000000a0a0a0a0a0a0a0acccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccca0a0a0a00000000000000000a0a0a0a0a0a0a0a0cccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccc0a0a0a0a00000000000000000a0a0a0a0a0a0a0acccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccca0a0a0a00000000000000000a0a0a0a0a0a0a0a0cccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccc0a0a0a0a00000000000000000a0a0a0a0a0a0a0acccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccca0a0a0a00000000000000000a0a0a0a0a0a0a0a0cccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccc0a0a0a0a00000000000000000a0a0a0a0a0a0a0acccccccccccccccccccccccccccccccccccccccc00000000000000000000000000000000cccccccc
cccccccca0a0a0a0cccccccccccccccccccccccca0a0a0a008888880a0a0a0a0a0a0a0a0000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccc0a0a0a0acccccccccccccccccccccccc0a0a0a0a888888880a0a0a0a0a0a0a0a000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccca0a0a0a0cccccccccccccccccccccccca0a0a0a008888888a0a0a0a0a0a0a0a0000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccc0a0a0a0acccccccccccccccccccccccc0a0a0a0a088888880a0a0a0a0a0a0a0a000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccca0a0a0a0cccccccccccccccccccccccca0a0a0a088888880a0a0a0a0a0a0a0a0000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccc0a0a0a0acccccccccccccccccccccccc0a0a0a0a888888880a0a0a0a0a0a0a0a000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccca0a0a0a0cccccccccccccccccccccccca0a0a0a008888880a0a0a0a0a0a0a0a0000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccc0a0a0a0acccccccccccccccccccccccc0a0a0a0a008888000a0a0a0a0a0a0a0a000000000000000000000000cccccccccccccccccccccccccccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0cccccccca0a0a0a0a0a0a0a0a0a0a0a00000000000000000a0a0a0a008888880a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0acccccccc0a0a0a0a0a0a0a0a0a0a0a0a00000000000000000a0a0a0a888888880a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0cccccccca0a0a0a0a0a0a0a0a0a0a0a00000000000000000a0a0a0a008888888a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0acccccccc0a0a0a0a0a0a0a0a0a0a0a0a00000000000000000a0a0a0a088888880a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0cccccccca0a0a0a0a0a0a0a0a0a0a0a00000000000000000a0a0a0a088888880a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0acccccccc0a0a0a0a0a0a0a0a0a0a0a0a00000000000000000a0a0a0a888888880a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccca0a0a0a0a0a0a0a0a0a0a0a0cccccccca0a0a0a0a0a0a0a0a0a0a0a00000000000000000a0a0a0a008888880a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccc0a0a0a0a0a0a0a0a0a0a0a0acccccccc0a0a0a0a0a0a0a0a0a0a0a0a00000000000000000a0a0a0a008888000a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccccccccccca0a0a0a0cccccccccccccccca0a0a0a008888880a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccccccccccc0a0a0a0acccccccccccccccc0a0a0a0a888888880a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccccccccccca0a0a0a0cccccccccccccccca0a0a0a008888888a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccccccccccc0a0a0a0acccccccccccccccc0a0a0a0a088888880a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccccccccccca0a0a0a0cccccccccccccccca0a0a0a088888880a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccccccccccc0a0a0a0acccccccccccccccc0a0a0a0a888888880a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccccccccccca0a0a0a0cccccccccccccccca0a0a0a008888880a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0cccccccc
cccccccccccccccc0a0a0a0acccccccccccccccc0a0a0a0a008888000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0acccccccc
cccccccc000000000000000000000000cccccccca0a0a0a008888880a0a0a0a00000000008888880a0a0a0a0a0a0a0a0000000000000000000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a888888880a0a0a0a00000000888888880a0a0a0a0a0a0a0a000000000000000000000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a008888888a0a0a0a00000000008888888a0a0a0a0a0a0a0a0000000000000000000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a088888880a0a0a0a00000000088888880a0a0a0a0a0a0a0a000000000000000000000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a088888880a0a0a0a00000000088888880a0a0a0a0a0a0a0a0000000000000000000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a888888880a0a0a0a00000000888888880a0a0a0a0a0a0a0a000000000000000000000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a008888880a0a0a0a00000000008888880a0a0a0a0a0a0a0a0000000000000000000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a008888000a0a0a0a00000000008888000a0a0a0a0a0a0a0a000000000000000000000000cccccccc
cccccccc000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a00888888000000000a0a0a0a0088888800888888000000000a0a0a0a000000000cccccccc
cccccccc0000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a88888888000000000a0a0a0a8888888888888888000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a00888888800000000a0a0a0a0088888880888888800000000a0a0a0a000000000cccccccc
cccccccc0000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a08888888000000000a0a0a0a0888888808888888000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a08888888000000000a0a0a0a0888888808888888000000000a0a0a0a000000000cccccccc
cccccccc0000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a88888888000000000a0a0a0a8888888888888888000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a00888888000000000a0a0a0a0088888800888888000000000a0a0a0a000000000cccccccc
cccccccc0000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a00888800000000000a0a0a0a0088880000888800000000000a0a0a0a00000000cccccccc
cccccccc888888888888888888888888cccccccca0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a000000000cccccccc
cccccccc888888888888888888888888cccccccc0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a000000000000000000000000000000000000000000000000000000000a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a000000000000000000000000000000000000000000000000000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a000000000000000000000000000000000000000000000000000000000a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a000000000000000000000000000000000000000000000000000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a000000000000000000000000000000000000000000000000000000000a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a000000000000000000000000000000000000000000000000000000000a0a0a0a00000000cccccccc
cccccccc000000000000000000000000cccccccca0a0a0a000000000000000000000000000000000000000000000000000000000a0a0a0a000000000cccccccc
cccccccc000000000000000000000000cccccccc0a0a0a0a000000000000000000000000000000000000000000000000000000000a0a0a0a00000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccca0a0a0a0000000000888888000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc0a0a0a0a0000000088888888000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a00000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccca0a0a0a0000000000888888800000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc0a0a0a0a0000000008888888000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a00000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccca0a0a0a0000000008888888000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc0a0a0a0a0000000088888888000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a00000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccca0a0a0a0000000000888888000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc0a0a0a0a0000000000888800000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a00000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc0888888000000000a0a0a0a000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc88888888000000000a0a0a0a000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a00000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc0888888800000000a0a0a0a000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc08888888000000000a0a0a0a000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a00000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc8888888000000000a0a0a0a000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc88888888000000000a0a0a0a000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a00000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc0888888000000000a0a0a0a000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a000000000cccccccc
ccccccccbbbbbbbbbbbbbbbbbbbbbbbbcccccccc00888800000000000a0a0a0a000000000a0a0a0a000000000a0a0a0a0a0a0a0a0a0a0a0a00000000cccccccc
cccccccccccccccccccccccccccccccccccccccca0a0a0a000000000a0a0a0a0000000000000000000000000a0a0a0a0a0a0a0a0a0a0a0a000000000cccccccc
cccccccccccccccccccccccccccccccccccccccc0a0a0a0a000000000a0a0a0a0000000008888880000000000a0a0a0a0a0a0a0a0a0a0a0a00000000cccccccc
cccccccccccccccccccccccccccccccccccccccca0a0a0a000000000a0a0a0a0000000008888888800000000a0a0a0a0a0a0a0a0a0a0a0a000000000cccccccc
cccccccccccccccccccccccccccccccccccccccc0a0a0a0a000000000a0a0a0a0000000008888888000000000a0a0a0a0a0a0a0a0a0a0a0a00000000cccccccc
cccccccccccccccccccccccccccccccccccccccca0a0a0a000000000a0a0a0a0000000000888888800000000a0a0a0a0a0a0a0a0a0a0a0a000000000cccccccc
cccccccccccccccccccccccccccccccccccccccc0a0a0a0a000000000a0a0a0a0000000088888880000000000a0a0a0a0a0a0a0a0a0a0a0a00000000cccccccc
cccccccccccccccccccccccccccccccccccccccca0a0a0a000000000a0a0a0a0000000008888888800000000a0a0a0a0a0a0a0a0a0a0a0a000000000cccccccc
cccccccccccccccccccccccccccccccccccccccc0a0a0a0a000000000a0a0a0a0000000008888880000000000a0a0a0a0a0a0a0a0a0a0a0a00000000cccccccc

__map__
4141414141414240434141414141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414142404040404043414141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040ff4040404040404040404040ff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4046464647404040404040ffffffff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
404646464646404040ffffff4040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
404640404046474646ff46474646464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4046464640464647ffff47464746474000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040464040464646ff4646464646464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000040474746ff474646ffffff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000046464647ff474646ff47ff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4045454540464646ff464646ff46ff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4000000040ffffffffffffff4746ff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4044444440ff4647ff4647ff4646ff4000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4044444440ff4746004746ff4647564000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040ff4646004646ff4646474000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4046464646ff4646004646000000464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4046000000474647564746464700464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4047004640404040404040404600474000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
404600464049494949494940ff00464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4046564740ffffffffffff404756464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40464746ff000000000000ff4647464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4046464640000000000000404646464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
40474646404b404bff404b404646464000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4040404040404040404040404040404000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
000100002332031320333203032029320313002c3000030000300003001e700007000020031200003000030000000000000000000000000000000000000000000000000000000000000000000000000000000000
00030000000002f7103471036710307102771021710177100c7100070000700007000070000700007000070000700007000070000700000000000000000000000000000000000000000000000000000000000000
000100000d05000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
