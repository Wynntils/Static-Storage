#!/usr/bin/perl

use strict;
use warnings;

# Check if the input file name is provided as the first argument
die "Usage: $0 <input_file>\n" unless @ARGV == 1;

# Get the input file name from the command line arguments
my $input_file = $ARGV[0];

# Open input file for reading
open my $fh, '<', $input_file or die "Cannot open $input_file: $!";

# Print the start of the JSON output
print "{ \"quests\": [\n";

# Initialize flag to track whether quests array has been started
my $quests_started = 0;
# Initialize flag to track whether a line has been printed for the current quest
my $line_printed = 0;
# Initialize flag to track whether a comma has been printed before quests
my $comma_printed = 0;

# Function to trim leading and trailing whitespace
sub trim {
    my $string = shift;
    $string =~ s/^\s+|\s+$//g;
    return $string;
}

# Process input file
while (my $line = <$fh>) {
    chomp $line;

    # Extract quest name
    if ($line =~ /^quest: "(.+)"/) {
        if ($quests_started) {
            # Close previous quest's lines array
            print "\n]}";
        }
        else {
            $quests_started = 1;
        }
        my $quest_name = $1;
        # Print comma before quest details if needed
        print "," if $comma_printed;
        $comma_printed = 1;
        # Print quest details
        print "\n{\"name\":\"$quest_name\",\"lines\":[";
        # Reset line_printed flag for the new quest
        $line_printed = 0;
    }

 # Extract line details
    elsif ($line =~ /^line: "(.*?)", "([a-zA-Z0-9-]+)", (true|false)(?:, (\d+))?/) {
        my ($msg, $sound, $ambient, $volume) = ($1, $2, $3, $4);
        # Split the msg further into num, max, name, and phrase
        if ($msg =~ /\[(\d+)\/(\d+)\] ([^:]+):(.+)/) {
            my ($num, $max, $name, $phrase) = ($1, $2, $3, trim($4));
            # Print comma before line details if needed
            print "," if $line_printed;
            # Print newline before line details
            print "\n" if $line_printed;
            # Print line details
            print "{\"num\":$num,\"max\":$max,\"speaker\":\"$name\",\"line\":\"$phrase\",\"id\":\"$sound\"";
            print ",\"follow_speaker\":$ambient" if $ambient eq 'true';
            print ",\"falloff\":$volume" if defined $volume;
            print "}";
            # Set line_printed flag to true
            $line_printed = 1;
        }
        else {
            # Print comma before line details if needed
            print "," if $line_printed;
            # Print newline before line details
            print "\n" if $line_printed;
            # Print line details
            print "{\"line\":\"$msg\",\"id\":\"$sound\"";
            print ",\"follow_speaker\":$ambient" if $ambient eq 'true';
            print ",\"falloff\":$volume" if defined $volume;
            print "}";
            # Set line_printed flag to true
            $line_printed = 1;
        }
    }
}

# Close input file
close $fh;

# Print the end of the JSON output
print "\n] }]}\n";
