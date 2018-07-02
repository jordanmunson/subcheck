#!//usr/local/bin/perl -w

use Getopt::Std;

my $counter = 0;              # Subtitle position
my $total;                    # Gathered of one subtitle unit
my @sublist;                  # All filtered subtitles
my @newSubList;               # Regenerated subtitles
my $msecsChar = 60;           # How many msecs per character
my $maxCharsLine = 40;        # Maximal characters per line
my $sepTime = 10;             # Minimal time between 2 subtitles (100 ms)
my $subLines = 2;             # Maximal lines per subtitle unit
my $fixNegValues = 1;         # If a subtitle hase a negative duration it will be fixed
my $removeTags = 1;           # If true (1) subcheck will remove tags
my $minTimeSubUnit = 600;     # The minimum count of msec for a normal subtitle unit
                              # (If the time is to big it will be over written by a value that fits)
my $checkErrors = 1;          # Check if there are any errors in the text lines
my $readOnly = 0;             # Readonly checking off
my $onlyToBig = 0;            # If 1 it will only fix to long (in characters) subtitles without the duration
my $onlyToBigTime = 0;        # If 1 it will only fix to long (in characters) subtitles including duration
my $onlyShortTime = 0;        # If 1 it will only fix subtitles with to short duration
my $quietMode = 0;            # No status output

sub floor {
    my($number) = shift;
        return int($number);
}

sub charCount {
    my $subtitle = shift;
    $subtitle =~ s/\n+//g;
    $subtitle =~ s/\r+//g;
    $subtitle =~ s/\s+//g;
    
    return length($subtitle);
}

sub getTimeLine {
    my $subtitle = shift;
    $subtitle =~ /.*([0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3} --> [0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3}).*/;
    return $1;
}

sub getLength_msec {
    my $subtitle = shift;
    $subtitle =~ /.*([0-9]{2}):([0-9]{2}):([0-9]{2}),([0-9]{3}) --> ([0-9]{2}):([0-9]{2}):([0-9]{2}),([0-9]{3}).*/;
    my $start = ($1 * 3600 * 1000) + ($2 * 60 * 1000) + ($3 * 1000) + $4;
    my $end = ($5 * 3600 * 1000) + ($6 * 60 * 1000) + ($7 * 1000) + $8;
    return $end - $start;
}

# Gets free space for a subtitle (number) until the next one
sub getFreeSpace_msec {
    my $subNumber = shift;
    my $space;

    if ($subNumber > ($counter -1)) {
        die "Index of subtitle number is to big.\n";
    }

    if (($subNumber+1) == $counter) {
        $space = 10000 + ($sepTime - 1);
    } else {
        my $cur_sub = $sublist[$subNumber];
        $cur_sub =~ /.*([0-9]{2}):([0-9]{2}):([0-9]{2}),([0-9]{3}) --> [0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3}.*/;
        my $start = ($1 * 3600 * 1000) + ($2 * 60 * 1000) + ($3 * 1000) + $4;

        my $next_sub = $sublist[$subNumber + 1];
        
        $next_sub =~ /.*([0-9]{2}):([0-9]{2}):([0-9]{2}),([0-9]{3}) --> [0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3}.*/;
        my $end = ($1 * 3600 * 1000) + ($2 * 60 * 1000) + ($3 * 1000) + $4;
        $space = $end - $start;
    }
    
    return $space;
}

sub getFirstTime {
    my $subtitle = shift;
    $subtitle =~ /([0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3}) --> [0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3}/;
    return $1;
}

sub timeIsBiggerThan {
    my $time1 = shift;
    my $time2 = shift;

    $time1 =~ /([0-9]{2}):([0-9]{2}):([0-9]{2}),([0-9]{3})/;
    my $first = ($1 * 3600 * 1000) + ($2 * 60 * 1000) + ($3 * 1000) + $4;

    $time2 =~ /([0-9]{2}):([0-9]{2}):([0-9]{2}),([0-9]{3})/;
    my $last = ($1 * 3600 * 1000) + ($2 * 60 * 1000) + ($3 * 1000) + $4;
    
    return ($first > $last) ? 1 : 0;
}

sub getLastTime {
    my $subtitle = shift;
    $subtitle =~ /[0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3} --> ([0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3})/;
    return $1;
}

sub getSubNumber {
    my $subtitle = shift;
    $subtitle =~ /^([0-9]+)/;
    return $1;
}

sub getTextLines {
    my $subtitle = shift;
    my @text = split(/\r\n/, $subtitle);
    shift @text;
    shift @text;
    
    return join("\r\n", @text);
}

# Get the length of the longest line in a subtitle
sub getMaxLength {
    my $subtitle = shift;
    my @sublines = split(/\r\n/, $subtitle);
    my $subLen = 0;
    foreach my $sub (@sublines) {
        if (length($sub) > $subLen) {
            $subLen = length($sub);
        }
    }
    return $subLen;
}

sub getWordCount {
    my $subtitle = shift;
    $subtitle =~ s/(\r\n)+/ /g;
    my @words = split(/\s+/, $subtitle);
    print join("\r\n", @words);
    return $#words + 1;
}

sub filterText {
    my $subtitle = shift;

    #Convert unix files to dos
    $subtitle =~ s/\r\n/\n/g;
    $subtitle =~ s/\n/\r\n/g;
    
    #Remove spaces between minus signs
    $subtitle =~ s/^\s*\-\s*(.*)/-$1/g;

    #Remove spaces between dots
    $subtitle =~ s/\s*\.(.*)/.$1/g;

    #Remove spaces between ?'s
    $subtitle =~ s/\s*\?(.*)/?$1/g;

    #Remove spaces between !'s
    $subtitle =~ s/\s*\!(.*)/!$1/g;

    #Remove spaces between ,'s
    $subtitle =~ s/\s*,(.*)/,$1/g;

    if ($removeTags) {
        #Remove tags
        $subtitle =~ s/<[A-Za-z0-9\\\/\.&\$\^\*\#\@\%\-]*>//g;
    }
    
    return $subtitle;
}

sub isCredit {
    my $subtitle = shift;
    my $returnCode = 0;
    if (($subtitle =~ /[vV][eE][rR][tT][aA][aA][lL][dD]/) ||
        ($subtitle =~ /[vV][eE][rR][tT][aA][lL][iI][nN][gG]/) ||
        ($subtitle =~ /[sS][uU][bB][bB][eE][dD]/) ||
        ($subtitle =~ /[sS][yY][nN][cD][eE][dD]/) ||
        ($subtitle =~ /[pP][iI][rR][aA][cC][yY]/) ||
        ($subtitle =~ /[oO][nN][dD][eE][rR][tT][iI][tT][eE][lL]/) ||
        ($subtitle =~ /[sS][uU][bB][tT][iI][tT][lL][eE]/) ||
        ($subtitle =~ /[wW][wW][wW]\./))
    {
        $returnCode = 1;
    }
    return $returnCode;
}

sub hasError {
    my $subtitle = shift;
    my $returnCode = 0;
    if (($subtitle =~ / --> /) ||
        ($subtitle =~ /([0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3})/))
    {
        $returnCode = 1;
    }
    return $returnCode;
}

sub isEmpty {
    my $subtitle = shift;
    $subtitle = getTextLines($subtitle);
    my $returnCode = 0;
    if ($subtitle =~ /^([^\S]*)$/) {
        $returnCode = 1;
    }
    return $returnCode;
}

sub writeToFile {
    my $filename = shift;
    open(NEWSUB, ">" . $filename) || die "Can't create file $filename.\n"; 
    print "Writing changes to file '$filename'...\n";
    for (my $i = 0; $i < $#newSubList + 1; $i++) {
        syswrite(NEWSUB, $i + 1 . "\r\n");
        syswrite(NEWSUB, $newSubList[$i] . "\r\n");
    }
    close(NEWSUB);
    print "Writing done.\n";    
}

# Adds a defined number of msecs to a timeline
# Usage: addTime("01:43:39,003", 3000); 
sub addTime {
    my $timeline = shift;
    my $add_msec = shift;
    my $returnString;
    if ($timeline !~ /([0-9]{2}):([0-9]{2}):([0-9]{2}),([0-9]{3})/) {
        die "Timeline is not in a correct format\n";
    } else {
        my $hours = $1;
        my $minutes = $2;
        my $seconds = $3;
        my $milSecs = $4 + $add_msec;
        
        # Spread the counts because its possible that we have a overflow

        my $tmilSecs = $milSecs;
        $milSecs = $tmilSecs % 1000;

        my $tseconds = floor($tmilSecs / 1000) + $seconds;
        $seconds = $tseconds % 60;

        my $tminutes = floor($tseconds / 60) + $minutes;
        $minutes = $tminutes % 60;

        $hours += floor($tminutes / 60);

        $returnString = sprintf "%.2d:%.2d:%.2d,%.3d", $hours, $minutes, $seconds, $milSecs;
    }
    return $returnString;
}

sub shortenLines {
    my $returnString;
    my $curLineLength = 0;
    my $curLine = 1;
    my $sep = '';
    my $lastChar = ""; # Last char of a word
    my $firstChar = ""; # Last char of a word
    my $lines = shift;
    $lines =~ s/\r\n/ /;
    my $totalLen = length($lines);

    my @words = split(/\s+/, $lines);
    
    for (my $i = 0; $i < $#words + 1; $i++) {
        $lastChar = substr($words[$i], length($words[$i]) - 1, 1);
        if (length($words[$i]) > 1) {
            $firstChars = substr($words[$i], 0, 2);
        } else {
            $firstChars = substr($words[$i], 0, 1);
        }

        # If first char is equal to - than begin on a new line
        if (( length($words[$i]) > 1) && ($firstChars =~ /-[A-Za-z]+/)) {
            $returnString .= "\r\n" . $words[$i];
            $curLineLength = length($words[$i]);
            $curLine++;
            $sep = ' ';
        
        
        } else { # Word doesn't begin with a - so treat it as normal
            
            if (($curLine % $subLines) != 0) { # Check if this is the last line of a subtitle unit
                # This is not the last line of a subtitle unit

                if ( ($curLineLength + length($words[$i]) + length($sep)) <= $maxCharsLine){
                    # This word fits on the current line
                    $returnString .= $sep . $words[$i];
                    $totalLen -= (length($sep) + length($words[$i]));
                    $curLineLength += length($words[$i]) + length($sep);
                    if ($sep eq '') {
                        $sep = ' ';
                    }
                    
                } else { # This word doesn't fit on the current line so break the line and add it on the new line
                    $returnString .= "\r\n" . $words[$i];
                    $totalLen -= (length($words[$i]) + 1); # +1 because we don't add a space
                    $curLine++;
                    $curLineLength = length($words[$i]);
                }
            } else {
                # This is the last line of a subtitle unit

                # Check 1) if the word fits on the line with 3 dots ...
                #       2) if it is a word ending with ! ? , . ands fits over the total line
                #       3) it the rest of all words fits on this line
                if ( ($curLineLength + length($words[$i]) + length($sep)) <= ($maxCharsLine - 3) ||
                     ((($curLineLength + length($words[$i]) + length($sep)) <= $maxCharsLine) && ($lastChar =~ /[\!\.\?,]/)) ||
                     ($curLineLength + $totalLen) <= ($maxCharsLine)) {
                    $returnString .= $sep . $words[$i];
                    $totalLen -= (length($sep) + length($words[$i]));
                    $curLineLength += length($words[$i]) + length($sep);
                    if ($curLineLength == $maxCharsLine) { # If line is completely full
                        $returnString .= "\r\n";
                        $curLineLength = 0;
                        $curLine++;
                        $sep = '';
                    } else {
                        if ($sep eq '') {
                            $sep = ' ';
                        }
                    }
                    
                } else {
                    if ($lastChar =~ /[A-Za-z0-9]+/) { # Word doesn't end with a ? , . !
                        $returnString .= "...\r\n" . $words[$i];
                        $totalLen -= (length($words[$i]) + 1); # +1 because we don't add a space
                    } else {
                        $returnString .= "\r\n" . $words[$i];
                        $totalLen -= (length($words[$i]) + 1); # +1 because we don't add a space
                    }
                    $curLine++;
                    $curLineLength = length($words[$i]);
                }            
            }
        }
    }
    return $returnString;
}

# This regenerates a subtitle into subtitles with a maximum length
# It's possible that the subtitles will be seperated
sub genSubtitle {
    my $maxTime = shift;
    my $subtitle = shift;    
    my $normalTime = shift; # Normal duration of the subtitle unit


    my $subText = getTextLines($subtitle);
    my @returnSubs; # Array with subs to return

    my $toShort = 0; # Is true if subtitle duration is shorter than $minTimeSubUnit

    my $rewriteTime = 0;   # If 0 subtitle doesn't need a rewrite of time line
    my $rewriteLength = 0; # If 0 subtitle doesn't need a rewrite of text lines

###<Rewrite checking>###
    if (!$onlyToBig && !$onlyToBigTime && !$onlyShortTime) {
        # No special setting so rewrite all subtitles
        $rewriteLength = 1;
        $rewriteTime = 1;
    } else {
        # Special setting set so check which thing need to be rewritten
        my $curTimePerChar = $normalTime / length($subText);    
        my $minTimePerChar = $minTimeSubUnit  / length($subText);
        
        #Check if the duration is smaller than $minTimeSubUnit
        if (($curTimePerChar < $minTimePerChar) && ($minTimeSubUnit > 0)) {
            if ($onlyShortTime || $onlyToBigTime) {
                # Rewrite duration
                $rewriteTime = 1;
            }           
        }

        if ((getMaxLength($subText) > $maxCharsLine) && ($curTimePerChar < $msecsChar)){
            # The subtitle text size is to big and the duration is to short
            if ($onlyToBig || $onlyToBigTime) {
                # Rewrite length
                $rewriteLength = 1;
            }
            if ($onlyShortTime || $onlyToBigTime) {
                # Rewrite duration
                $rewriteTime = 1;
            }
            
        } elsif (getMaxLength($subText) > $maxCharsLine) {
            # The subtitle text size is to big
            if ($onlyToBig || $onlyToBigTime) {
                # Rewrite length
                $rewriteLength = 1;
            }
        } elsif ($curTimePerChar < $msecsChar) {
            # The subtitle duration is to short
            if ($onlyShortTime || $onlyToBigTime) {
                # Rewrite duration
                $rewriteTime = 1;
            }
        }
    }

###</Rewrite checking>###

    my $firstTime = getFirstTime($subtitle);

    # Lines of the reformatted subtitle
    my @lines = split(/\r\n/, $subText);
    if ($rewriteLength) {
        @lines = split(/\r\n/, shortenLines($subText));
    }

    my $lineCount = $#lines;

    # Calculate needed subtitle units
    my $neededUnits = 0;
    if ($rewriteLength) {
        $neededUnits = floor($#lines / $subLines);
        if ((($#lines % $subLines) != 0) && ($#lines != 1)) {
            $neededUnits++;
        }
    }

    my $tmpSubTextShort = shortenLines($subText);
    $tmpSubTextShort  =~ s/\r\n//g; # Remove "\r\n" so we don't count it with length
    my $tmpSubText = $subText;
    $tmpSubText  =~ s/\r\n//g; # Remove "\r\n" so we don't count it with length

    # Calculate how many time we need for all characters
    my $neededTime = length($tmpSubText) * $msecsChar; # If rewriteLength is not set
    if ($rewriteLength) { # If rewriteLength is set
        $neededTime = (length($tmpSubTextShort) * $msecsChar);
    }

    #Check if $neededTime is smaller than $minTimeSubUnit
    if ($minTimeSubUnit > 0) {
        if ($minTimeSubUnit > $neededTime) {
            $neededTime = $minTimeSubUnit;
        }
    }
    
    # If it is not needed to rewrite subtitle unit than return
    if (!$rewriteLength && !$rewriteTime) {
        push(@returnSubs, getTimeLine($subtitle) . "\r\n" . getTextLines($subtitle) . "\r\n");   
        return @returnSubs;
    }

    my $usableTimePerChar;

    # Calculate duration of each character
    if ($rewriteTime) {
        my $charCount  = $tmpSubText;
        if ($rewriteLength) {
            $charCount = $tmpSubTextShort;
        }

        # Add pauses needed between units
        $neededTime += $sepTime * $neededUnits;
        
        # Check if we have enough time
        if ($neededTime > $maxTime) {
            #Calculate how many msecs we have for each character
            $usableTimePerChar = $maxTime - ($sepTime * $neededUnits);
            #floored#
            $usableTimePerChar = $usableTimePerChar / length($charCount);
        } else {
            $usableTimePerChar = $msecsChar;
        }
    } elsif ($rewriteLength) {
        #floored#
        $usableTimePerChar = ($normalTime - ($sepTime * $neededUnits)) / length($tmpSubTextShort);
    }

    # Generate new subtitle units
    my $tmpSubUnit = "";
    my $tmpNextTime = $firstTime;
    my $position = 0;
    my $curDuration = 0;
    my $curUnit = $neededUnits;
    $maxTime -= ($sepTime * $neededUnits); # Used to check how much time there is left
    my $setLastUnitDone = 0; # If 1 the time for the last subtitle unit is al ready set
    foreach my $line (@lines) {
        if ($line ne '') { # Filter out possible empty lines
            $position++;
            $tmpSubUnit .= "$line\r\n";
            my $useTime = (length($line) * $usableTimePerChar);
            if (($curUnit == 0) && ($minTimeSubUnit > 0) && !$setLastUnitDone) { # Last subtitle unit
                if (!$onlyToBig || $rewriteTime) {
                    if ($maxTime < $minTimeSubUnit) { # Check if the duration is to short                                          
                        if ($maxTime > $minTimeSubUnit) {
                            $useTime = $minTimeSubUnit;
                        } else {
                            $useTime = $maxTime;
                        }
                    } else { # Needed time for subtitle unit is long enough
                        if ($neededTime <= $maxTime) {
                            $useTime = $neededTime;
                        } else {
                            $useTime = $maxTime;
                        }
                    }
                    $tmpNextTime = addTime($tmpNextTime, floor($useTime));
                    $curDuration = floor($useTime);
                    $maxTime -= floor($useTime);
                    $setLastUnitDone = 1;             
                }
            }
            if (!$setLastUnitDone) {
                $tmpNextTime = addTime($tmpNextTime, floor($useTime));
                $curDuration += floor($useTime);
                $maxTime -= floor($useTime); 
                $neededTime -= floor($useTime);
            }

            if (($position == $subLines) || ($lineCount == 0)) {
                # Set time tag and add unit to array returnSubs
                $tmpSubUnit = "$firstTime --> $tmpNextTime\r\n$tmpSubUnit";
                push(@returnSubs, $tmpSubUnit);
                # Reset variables
                $position = 0;

                # Add unitseperation time
                $firstTime = addTime($tmpNextTime, $sepTime);
                $tmpNextTime = addTime($tmpNextTime, $sepTime);

                $tmpSubUnit = "";
                $curDuration = 0;
                $curUnit--;                
            }
            $lineCount--;
        }
    }
    return @returnSubs;
}

sub isRealSub {
    my $subtitle = shift;
    my $returnCode = 0;
    if ($subtitle =~ /^[0-9]+\r\n[0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3} --> [0-9]{2}:[0-9]{2}:[0-9]{2},[0-9]{3}\r\n.*/) {
        $returnCode = 1;
    }
    return $returnCode;
}

# Check if the subtitle-unit is valid
sub checkToKeepSub {
    my $lastTime = "00:00:00,000";
    if (!isRealSub($total)) {   # Total empty string no subtitle unit
        if (!$quietMode) {
            if ($counter > 0) {
                print "Removing bogus subtitle unit after subtitle unit " . 
                    getSubNumber($sublist[$counter-1]) . " \n" .
                    "Containing the following:\n[$total]\n" ;
            } else {
                print "Removing bogus subtitle unit (first subtitle unit in SRT file)\n" . 
                    "Containing the following:\n[$total]\n" ;
            }
        }
        $total = '';
        return;
    }
    
    # Check if the duration of the subtitle is not negative
    if (timeIsBiggerThan(getFirstTime($total), getLastTime($total))) {
        if ($readOnly) {
            if (!$quietMode) {
                print "[ERROR] Duration of sub ". ($counter + 1) ." is negative\n";
            }
        } else {
            if ($fixNegValues) {
                $total = getSubNumber($total) . "\n" . getFirstTime($total) .
                    " --> " . getFirstTime($total) . "\n" . getTextLines($total);
            } else {
                close(SUBFILE);
                die "[ERROR] Duration of sub ". ($counter + 1) ." is negative\n";
            }
        }
    }
    
    # Check if the subtitle unit isn't overlapping with previous subs
    if (timeIsBiggerThan($lastTime, getFirstTime($total))){
        if ($readOnly) {
            if (!$quietMode) {
                print "[ERROR] Subtitle unit ". getSubNumber($sublist[$counter-1]) .
                    " is overlapping subtitle unit " . getSubNumber($total) . "\n" .
                    "Firsttime (sub " . getSubNumber($total) ."): " . getFirstTime($total) . 
                    " overlaps previous lasttime: $lastTime\n";
            }
        } else {
            close(SUBFILE);
            die "[ERROR] Subtitle unit ". getSubNumber($sublist[$counter-1]) .
                " is overlapping subtitle unit " . getSubNumber($total) . "\n" .
                "Firsttime (sub " . getSubNumber($total) ."): " . getFirstTime($total) . 
                " overlaps previous lasttime: $lastTime\n";
        }
    } else {
        $lastTime = getLastTime($total);
    }
    
    if (!isEmpty($total)) {
        my $keepIt = 1;
        if (isCredit($total)) {
            if ($readOnly) {
                if (!$quietMode) {
                    print "The following seems to be a credit:\n$total";
                }
            } else {
                print "The following seems to be a credit:\n$total";
                print "\n\nDo you want to keep it? [N/y] : ";
                my $readInput = <STDIN>;
                chomp $readInput;
                if (($readInput =~ /^[Nn]/) || (length($readInput) == 0)) {
                    $keepIt = 0;
                    if (!$quietMode) {
                        print "Removing credit...\n";
                    }
                } else {
                    if (!$quietMode) {
                        print "Keeping credit...\n";
                    }
                }
            }
        }
        if ($keepIt == 1) {
            if (hasError(getTextLines($total)) && $checkErrors) {
                if ($readOnly) {
                    if (!$quietMode) {
                        print "[ERROR] It seems that the following subtitle has an error:\n$total\n";
                    }
                } else {
                    close(SUBFILE);
                    print "[ERROR]It seems that the following subtitle has an error:\n$total\n";
                    die "Please correct it and run subcheck again.\n";
                }
            }
            
            # Print message if the subtitle length is to long
            if (getMaxLength(getTextLines($total)) > $maxCharsLine) {
                if (!$quietMode) {
                    print "\n------------------------------------------------------\n";
                    print "Subtitle " . getSubNumber($total) . " is " . getMaxLength(getTextLines($total)) .
                        " characters long. This is larger than the max character count of " . $maxCharsLine . ".\n";
                    print "------------------------------------------------------\n";
                }
            }
            
            if ($keepIt) {
                my $len = getLength_msec($total);
                my $chars = charCount(getTextLines($total));
                if ((($len / $chars) < $msecsChar) && 
                    (($onlyToBigTime || $onlyShortTime) || 
                     (!$onlyToBig && !$onlyToBigTime && !$onlyShortTime))){
                    if (!$quietMode) {
                        print "\n------------------------------------------------------\n";
                        print "Subtitle " . getSubNumber($total) . " is too short.";
                        print " Its duration is $len but should be " . $chars * $msecsChar . ".\n";
                        print "------------------------------------------------------\n";
                    }
                }
                $counter++;
                push(@sublist, $total);
            }
        } else {
            if (!$quietMode) {
                print "Ignoring empty lines...\n";
            }
        }
    }
    $total = "";

}

sub loadFromFile {
    my $loadFile = shift;
    if ($loadFile !~ /\.[Ss][Rr][Tt]$/) {
        die "It is only possible to open files with a srt extension!\n";
    }
    open(SUBFILE, "<".$loadFile) || die "Can't open subtitle file '$loadFile'.\n"; 

    my $filtered;
    my $bufferFull = 0;
    while (<SUBFILE>) {    
        $filtered = filterText($_);
        if ($filtered =~ /^\s*\r\n$/) { # We reached a new subtitle unit
            checkToKeepSub();
            $bufferFull = 0;
        } else {
            $total .= $filtered;
            $bufferFull = 1;
        }
    }
    
    #Check if buffer is still full. If so check is content is valid
    if ($bufferFull) {
       checkToKeepSub();
       $bufferFull = 0;
    }
    
    close(SUBFILE);
}

sub generateNewSubs {
    @newSubList = ();
    for (my $i = 0; $i < $#sublist + 1; $i++) {
        foreach my $tmpSub (genSubtitle(getFreeSpace_msec($i) - $sepTime, $sublist[$i], getLength_msec($sublist[$i]))) {
           push(@newSubList, $tmpSub);
        }
    }
}

%options=();
getopts("i:o:m:l:s:ftd:c:rbBTSq",\%options);
if (!defined $options{i}) {
    print "-------------------------------SubCheck 0.78.2---------------------------------\n\n ";    
    print " Usage : $0 [-i FILE] [-o FILE] [-m NUMBER] [-l NUMBER] ...\n";
    print "                    [-s NUMBER] [-f] [-t] [-d NUMBER] [-c NUMBER] [-e] ...\r\n";
    print "                    [-r] [-b] [-B] [-T] [-q]\n\n";
    print " Options:                                                     (DEFAULT)\n";
    print "   -i   : Input file                                          ()\n";
    print "   -o   : Output file                                         (Input file)\n";
    print "   -m   : Number of milliseconds per character                (60)\n";
    print "   -l   : Line count per subtitle unit                        (2)\n";
    print "   -s   : Time in milliseconds between two subtitle units     (10)\n";
    print "   -f   : Disable fix negative duration of subtitle units     (FALSE)\n";
    print "   -t   : Disable remove tags                                 (FALSE) \n";
    print "   -d   : Minimal duration of a subtitle unit in milliseconds (600)\n";
    print "   -c   : Maximal characters per line                         (40)\n";
    print "   -e   : Disable check for errors in the text lines          (FALSE)\n";
    print "   -r   : Readonly mode, shows errors and quit (overwrites -o)(FALSE)\n";
    print "   -b   : Only rewrite subtitle if it exceeds maximal \n";
    print "          characters per line but don't rewrite duration      (FALSE)\n";
    print "   -B   : Only rewrite subtitle if it exceeds maximal \n";
    print "          characters per line and rewrite duration            (FALSE)\n";
    print "   -T   : Only rewrite subtitle if it's duration is to short  (FALSE)\n";
    print "   -q   : Quiet mode                                          (FALSE)\n\n\n";
    print "  Author:  H.J. Kamphorst (2004)           [hkamphor\@users.sourceforge.net ]\n";
    print "                                           [http://subcheck.sourceforge.net]\n";
} else {

    binmode STDOUT, ':utf8';

    my $inputFile = $options{i};
    my $outputFile = $options{i};
    
    if (defined $options{o}) {
        $outputFile = $options{o};
    }

    if (defined $options{m}) {
        $msecsChar = $options{m};
    }

    if (defined $options{l}) {
        $subLines = $options{l};
    }

    if (defined $options{s}) {
        $sepTime = $options{s};
    }

    if (defined $options{f}) {
        $fixNegValues = 0;
    }

    if (defined $options{t}) {
        $removeTags = 0;
    }

    if (defined $options{d}) {
        $minTimeSubUnit = $options{d};
    }

    if (defined $options{c}) {
        $maxCharsLine = $options{c};
    }

    if (defined $options{e}) {
        $checkErrors = 0;
    }
    
    if (defined $options{r}) {
        $readOnly = 1;
    }

    if (defined $options{b}) {
        $onlyToBig = 1;
    }

    if (defined $options{B}) {
        $onlyToBigTime = 1;
    }

    if (defined $options{T}) {
        $onlyShortTime = 1;
    }

    if (defined $options{q}) {
        $quietMode = 1;
    }

    if ($readOnly) {
        print "Start checking of [$inputFile] in readonly mode...\n";
    } else {
        print "Start checking of [$inputFile]...\n";
    }

    loadFromFile($inputFile);
    generateNewSubs();

    if (!$readOnly) {
        writeToFile($outputFile);
    }
    print "Checking finished.\n";
}

