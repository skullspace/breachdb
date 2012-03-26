#!/usr/bin/env ruby

@l33t = [
  ["a", "4"],
  ["a", "@"],
  #["a", "/-\\"],
  #["a", "/\\"],
  #["a", "^"],

  ["b", "8"],
  #["b", "|3"],
  #["b", "13"],
  #["b", "l3"],
  #["b", "]3"],

  ["c", "("],
  #["c", "<"],
  #["c", "{"],
  ["c", "©"],

  #["d", "|)"],
  #["d", "[)"],
  #["d", "])"],
  #["d", "I>"],
  #["d", "|>"],

  ["e", "3"],
  #["e", "&"],
  #["e", "[-"],

  #["f", "!="],
  #["f", "]="],
  #["f", "}"],
  #["f", "(="],

  ["g", "6"],
  #["g", "&"],

  #["h", "|-|"],
  #["h", "#"],
  #["h", "]-["],
  #["h", "[-]"],
  #["h", "(-)"],
  #["h", ")-("],

  #["i", "!"],
  ["i", "1"],
  ["i", "|"],

  #["j", "_|"],
  #["j", "_/"],
  #["j", "]"],

  #["k", "X"],
  #["k", "|<"],
  #["k", "|X"],
  #["k", "|{"],

  ["l", "1"],
  #["l", "7"],
  #["l", "I_"],
  ["l", "|"],
  #["l", "|_"],

  #["m", "/\\/\\"],
  #["m", "|\\/|"],
  #["m", "|v|"],
  #["m", "[v]"],
  #["m", "[V]"],

  #["n", "|\\|"],
  #["n", "/\\/"],

  ["o", "0"],
  ["o", "()"],
  #["o", "[]"],

  #["p", "|*"],
  ["p", "|o"],
  #["p", "|\""],
  #["p", "þ"],

  #["q", "0_"],
  #["q", "O_"],
  #["q", "0,"],
  #["q", "O,"],

  ["r", "|2"],
  #["r", "2"],
  #["r", "/2"],
  #["r", "I2"],
  #["r", "|^"],
  #["r", "|2"],

  ["s", "5"],
  ["s", "$"],
  #["s", "z"],
  #["s", "§"],

  ["t", "7"],
  ["t", "+"],
  #["t", "-|-"],
  #["t", "1"],
  #["t", "']['"],

  #["u", "|_|"],
  #["u", "(_)"],
  #["u", "[_]"],
  #["u", "\\_/"],

  #["v", "\\/"],

  #["w", "\\/\\/"],
  #["w", "vv"],
  #["w", "\\^/"],
  #["w", "\\x/"],
  #["w", "\\|/"],

  ["x", "%"],
  ["x", "><"],
  #["x", "*"],

  #["y", "j"],
  ["y", "`/"],

  #["z", "2"],
  #["z", "%"],
]

@accents = [
  ['a', 'à'],
  ['a', 'À'],
  ['a', 'â'],
  ['a', 'Â'],
  ['a', 'ä'],
  ['a', 'Ä'],
  ['a', 'æ'],
  ['a', 'Æ'],

  ['c', 'ç'],
  ['c', 'Ç'],

  ['e', 'é'],
  ['e', 'É'],
  ['e', 'è'],
  ['e', 'È'],
  ['e', 'ê'],
  ['e', 'Ê'],
  ['e', 'ë'],
  ['e', 'Ë'],
  ['e', 'œ'],
  ['e', 'Œ'],
  ['e', 'æ'],
  ['e', 'Æ'],

  ['i', 'î'],
  ['i', 'Î'],
  ['i', 'ï'],
  ['i', 'Ï'],

  ['o', 'ô'],
  ['o', 'Ô'],
  ['o', 'œ'],
  ['o', 'Œ'],

  ['u', 'ù'],
  ['u', 'Ù'],
  ['u', 'û'],
  ['u', 'Û'],
  ['u', 'ü'],
  ['u', 'Ü'],
]



# @replacements = @accents
@replacements = @l33t

def l33t(str, start, depth)
  if(depth > 8)
    return
  end

  start.upto(str.length) { |i|
    c = str[i..i]
    @replacements.each { |replacement|
      from = replacement[0]
      to   = replacement[1]

      if(c == from)
        new_str = String.new(str)
        new_str[i] = to
        puts(new_str)
        l33t(new_str, i, depth + 1)
      end
    }
  }
end

STDIN.read.split("\n").each do |a|
  l33t(a, 0, 0)
end

