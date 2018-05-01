#!/usr/bin/perl -Tw

use AppConfig;
use Carp;
use DBI;
use String::Util 'trim';
use LWP::Online;
use LWP::Simple;

use strict;
use vars qw/ $CONFIG $VERSION /;

# The ipacct tutorial on the perlmonks website was used as a model for our database modification.
# The base for this code can be found at http://www.perlmonks.org/?node_id=214320.
# Where a double space precedes comments, these are from the original tutorial.  

BEGIN {
    $CONFIG = AppConfig->new({
        'CASE'              =>  0,
        'GLOBAL'            =>  { 'ARGCOUNT' => 1 }
    },
        'configuration|c'   =>  { 'DEFAULT' => undef },
        'database|d'        =>  { 'DEFAULT' => 'DBI:mysql:database=development;host=localhost;password=rock64' },
        'filter|f'          =>  { 'DEFAULT' => 'none' },
        'interface|i'       =>  {
            'DEFAULT'           =>  eval {
                my $err;
                my $dev = Net::Pcap::lookupdev( \$err );
                if ( defined $err ) {
                    croak( 'Cannot determine network interface for packet capture - ', $err );
                }
                $dev;
            }
        },
        'mtu|m'             =>  { 'DEFAULT' => 1500 },
        'password'          =>  { 'DEFAULT' => undef },
        'table|t'           =>  { 'DEFAULT' => 'blocklist' },
        'username'          =>  { 'DEFAULT' => undef }
    );
    $CONFIG->args;
    if ( defined $CONFIG->get('configuration') ) {

        #   If the configuration file parameter is defined on the command line via
        #   the -c switch, attempt to load the specified configuration file

        if ( $CONFIG->file( $CONFIG->get('configuration') ) ) {
            croak( 'Cannot open configuration file ', $CONFIG->get('configuration'), ' - ', $! );
        }

    }

    $VERSION = '0.3';
}




# Open database "development".
my $dbh;
unless ( $dbh = DBI->connect(
    $CONFIG->get('database'),
    $CONFIG->get('username'),
    $CONFIG->get('password'),
    { 'RaiseError' => 1 }
) ) {
    croak( 'Cannot connect to storage database - ', $! );
}

my $file;

# This part tests whether we are online to know whether we can pull from our
# designated blocklist at this moment.  If we are offline, we cannot.
if (!LWP::Online::online()) {
   print STDERR "You are offline and cannot pull from the blocklist.\n";
}

# If we are online, then we pull from myip.ms. This program is formatted to parse
# from this specific blocklist, and syntax modifications would be necessary if 
# this blocklist is replaced in future iterations of this code.
else {
   my $text = get "http://myip.ms/files/blacklist/general/latest_blacklist.txt";
   open $file, '<', \$text or die "Could not open blocklist website.\n";
}




# for each IP address before the # in each line
while (my $line = <$file>){
	chomp $line;


	# Consume lines that start with # or nothing until we get to the first number
	my $ip = trim(substr($line, 0, rindex($line,"#")));


    # We should check to make sure this is an IPv4 address and not an IPv6 address
    # or just blank space.
	if(length($ip) <= 16 && length($ip) >= 7 && rindex($ip, ":") < 0){


	# if not already in blocklist, then add to blocklist with a timestamp.
		$dbh->do(qq/
           INSERT IGNORE INTO / . 'blocklist' . qq/
                       (
                           blocklist_ip
                       )
               VALUES
                       ( ? )
       /,
           undef,
            $ip # our IP from the text file
       );
	}
}

__END__
