# subcheck

## About

From Sourceforge: http://subcheck.sourceforge.net/

This repository is so when I share this with my coworkers I don't need to instruct them on how to change all this stuff to work around OS X's rootless changes for El Capitan and later. All credit to the author for this really handy tool.

## Requirements

GNU make (For installation)
Perl

## Installation

Pull down this repository, and from that directory run `make install`, which should handle the rest based on the Makefile.

## Installation Troubleshooting

Make sure you've got perl installed in your `/usr/local/bin` -- if you have homebrew installed, this is as simple as running `brew install perl`

## Usage

To use this tool, you'll always start with `subcheck.pl` -- here's the manual:

```
  Usage : /usr/local/bin/subcheck.pl [-i FILE] [-o FILE] [-m NUMBER] [-l NUMBER] ...
                    [-s NUMBER] [-f] [-t] [-d NUMBER] [-c NUMBER] [-e] ...
                    [-r] [-b] [-B] [-T] [-q]

 Options:                                                     (DEFAULT)
   -i   : Input file                                          ()
   -o   : Output file                                         (Input file)
   -m   : Number of milliseconds per character                (60)
   -l   : Line count per subtitle unit                        (2)
   -s   : Time in milliseconds between two subtitle units     (10)
   -f   : Disable fix negative duration of subtitle units     (FALSE)
   -t   : Disable remove tags                                 (FALSE)
   -d   : Minimal duration of a subtitle unit in milliseconds (600)
   -c   : Maximal characters per line                         (40)
   -e   : Disable check for errors in the text lines          (FALSE)
   -r   : Readonly mode, shows errors and quit (overwrites -o)(FALSE)
   -b   : Only rewrite subtitle if it exceeds maximal
          characters per line but don't rewrite duration      (FALSE)
   -B   : Only rewrite subtitle if it exceeds maximal
          characters per line and rewrite duration            (FALSE)
   -T   : Only rewrite subtitle if it's duration is to short  (FALSE)
   -q   : Quiet mode                                          (FALSE)
```

## Examples

Running defauly autofixes for a file, which should be run _in the directory featuring the busted file:

```
subcheck.pl -i busted_file.srt -o new_fixed_file.srt
```

That will create a new file in the same directory with automatic fixes applied based on subcheck's defalts.