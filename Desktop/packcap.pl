#!/usr/bin/perl -Tw

use AppConfig;
use Carp;
use DBI;
use Net::Pcap;
use NetPacket::Ethernet;
use NetPacket::IP qw/ :protos /;
use NetPacket::TCP;
use NetPacket::UDP;
use NetPacket::ICMP;

use strict;
use vars qw/ $CONFIG $VERSION /;

# The ipacct tutorial on the perlmonks website was used as a model for our program.
# The base for this code can be found at http://www.perlmonks.org/?node_id=214320.
# Where a double space precedes comments, these are from the original tutorial.  

BEGIN {
    # In our config, we allow for config fields to be modified with flags, allowing packet capture on separate interfaces.
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
        'table|t'           =>  { 'DEFAULT' => 'ipacct' },
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


#   Create database handle for storage of general captured packet information.

my $dbh;
unless ( $dbh = DBI->connect(
    $CONFIG->get('database'),
    $CONFIG->get('username'),
    $CONFIG->get('password'),
    { 'RaiseError' => 1 }
) ) {
    croak( 'Cannot connect to storage database - ', $! );
}


#   The $err variable is passed as a reference to libpcap library methods for
#   returning error messages from this library.

my $err;


#   The lookupnet method of the libpcap library is used to validate the device 
#   argument specified for packet sniffing and capture.  This method also
#   returns the interface address and network mask for the device specified,
#   the latter of which is required for the compilation of a packet filter
#   should such a filter be specified.

my ( $address, $netmask );
if ( Net::Pcap::lookupnet( $CONFIG->get('interface'), \$address, \$netmask, \$err ) ) {
    croak( 'Unable to look up device information for ', $CONFIG->get('interface'), ' - ', $err );
}


#   The open_live method of the libpcap library will open the device $dev for
#   packet sniffing and capture.  The second argument passed to this method
#   is intended to be the maximum number of bytes to capture from each packet 
#   for which the maximal transmission unit for the interface is recommended.
#   As this parameter cannot be reliably determined programmatically in a 
#   portable fashion, this value can be specified in the configuration file
#   via the 'mtu' configuration parameter.
#
#   Furthermore, this packet capture method will set the device in promiscuous
#   mode for continuous packet capture.

my $pcap;
$pcap = Net::Pcap::open_live( $CONFIG->get('interface'), $CONFIG->get('mtu'), 1, -1, \$err );
unless ( defined $pcap ) {
    croak( 'Unable to open device for packet capture - ', $err );
}


#   If the filter configuration parameter is set to anything other than 
#   'none', the default value for this parameter, then this parameter is used
#   to build a filter for the packet sniffing and capture interface.
#
#   This is particularly useful if the storage database resides on another 
#   host so that the network traffic generated from data storage is not also
#   logged.

if ( $CONFIG->get('filter') ne 'none' ) {

    my $compile;
    if ( Net::Pcap::compile( $pcap, \$compile, $CONFIG->get('filter'), 0, $netmask ) ) {
        croak( 'Unable to compile packet capture filter' );
    }
    if ( Net::Pcap::setfilter( $pcap, $compile ) ) {
        croak( 'Unable to set compiled packet capture filter on packet capture device' );
    }

}


#   Initiate packet capture on the specified network device - All captured 
#   packets are passed to the &capture subroutine where packet decoding and 
#   recording of pertinent traffic information to the accounting database is
#   carried out.
#
#   The database handle is passed as the user data argument to the packet 
#   capture processing subroutine - This alleviates the requirement for a 
#   globally scoped database statement handle for the storage of captured 
#   packet information.

unless ( Net::Pcap::loop( $pcap, -1, \&capture, $dbh ) ) {
    croak( 'Unable to initiate packet capture for device ', $CONFIG->get('interface') );
}

Net::Pcap::close( $pcap );


sub capture {
    my ( $dbh, $header, $packet ) = @_;

    #   Strip ethernet encapsulation of captured network packet

    my $ether = NetPacket::Ethernet->decode( $packet );

    #   Decode contents of IP packet contained within stripped ethernet packet
    #   and decode the packet data contents if the encapsulated packet is 
    #   either TCP or UDP

    my $proto;
    my $ip = NetPacket::IP->decode( $ether->{'data'} );
    if ( $ip->{proto} == IP_PROTO_TCP ) {

        $proto = NetPacket::TCP->decode( $ip->{'data'} );

    } elsif ( $ip->{proto} == IP_PROTO_UDP ) {

        $proto = NetPacket::UDP->decode( $ip->{'data'} );

    } elsif ( $ip->{proto} == IP_PROTO_ICMP ){          # We have modified our code
                                                        # to be able to monitor ICMP
                                                        # packets as well, as these are
                                                        # frequently used for DDoS attacks.
	$proto = NetPacket::ICMP->decode ($ip->{'data'} );
	$proto->{'src_port'} = 0;
	$proto->{'dest_port'} = 0;
    }

    else {
        
        #   Unsupported network packet protocol - Currently, only TCP and UDP packets
        #   are decoded with all other packet types silently dropped by this 
        #   accounting process.

    }

    #   If the network packet encapsulated within the ethernet frame has been
    #   successfully recognised and decoded, insert relevant information with
    #   respect to source, destination and packet length into storage database.

    if ( defined $proto ) {

        #   Insert the source, destination and packet length information into storage
        #   database - Note that $proto->{'flags'} is not defined for NetPacket::UDP
        #   objects and in place the invalid flag value of -1 is inserted.
        #   
        #   The database table structure is as follows:
        #   
        #       CREATE TABLE ipacct2 (
        #         src_ip varchar(16) NOT NULL default '0.0.0.0',
        #         src_port smallint(5) unsigned NOT NULL default '0',
        #         dest_ip varchar(16) NOT NULL default '0.0.0.0',
        #         dest_port smallint(5) unsigned NOT NULL default '0',
        #         protocol tinyint(4) NOT NULL default '-1',
        #         length smallint(6) NOT NULL default '-1',
        #         flags smallint(6) NOT NULL default '-1',
        #         timestamp timestamp NOT NULL
        #       ) ENGINE=MyISAM;
        #
        # This database structure has been modified for our uses.

        $dbh->do(qq/
            INSERT INTO / . $CONFIG->get('table') . qq/
                        (
                            src_ip,
                            src_port,
                            dest_ip,
                            dest_port,
                            protocol,
                            length,
                            flags
                        )
                VALUES
                        ( ?, ?, ?, ?, ?, ?, ? )
        /,
            undef,
            $ip->{'src_ip'},
            $proto->{'src_port'},
            $ip->{'dest_ip'},
            $proto->{'dest_port'},
            $ip->{'proto'},
            $ip->{'len'},
            ( exists $proto->{'flags'} ) ? $proto->{'flags'} : -1
        );

    }
}


__END__
