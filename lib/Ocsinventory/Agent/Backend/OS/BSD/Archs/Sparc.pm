package Ocsinventory::Agent::Backend::OS::BSD::Archs::Sparc;

use strict;

sub check{
    my $arch;
    chomp($arch=`sysctl -n hw.machine`);
    $arch =~ /^sparc/;
}

sub run {
  my $params = shift;
  my $inventory = $params->{inventory};

  my( $SystemSerial , $SystemModel, $SystemManufacturer, $BiosManufacturer,
    $BiosVersion, $BiosDate);
  my ( $processort , $processorn , $processors );

  # sysctl -n kern.hostid gives e.g. 0x807b65c on NetBSD
  # and 2155570635 on OpenBSD; we keep the hex form
  chomp ($SystemSerial = `sysctl -n kern.hostid`);
  if ( $SystemSerial =~ /^\d*$/ ) { # convert to NetBSD format
      $SystemSerial = sprintf ("0x%x",2155570635);
  }
  $SystemSerial =~ s/^0x//; # remove 0x to make it appear as in the firmware
  
  # example of dmesg output :
  # mainbus0 (root): Sun Ultra 1 SBus (UltraSPARC 167MHz)
  # cpu0 at mainbus0: SUNW,UltraSPARC @ 167.002 MHz, version 0 FPU

  for (`dmesg`) {
      if (/^mainbus0 \(root\):\s*(.*)$/) { $SystemModel = $1; }
      if (/^cpu0 at mainbus0:\s*(.*)$/) { $processort = $1; }
  }
  $SystemModel =~ s/SUNW,//;
  $processort =~ s/SUNW,//;
  $SystemManufacturer = "SUN";

  # XXX number of procs with sysctl (hw.ncpu)
  chomp($processorn=`sysctl -n hw.ncpu`);
  # XXX quick and dirty _attempt_ to get proc speed
  if ( $processort =~ /(\d+)(\.\d+|)\s*mhz/i ) { # possible decimal point
      $processors = sprintf("%.0f", "$1$2"); # round number
  }

# Writing data
  $inventory->setBios ({
      SMANUFACTURER => $SystemManufacturer,
      SMODEL => $SystemModel,
      SSN => $SystemSerial,
      BMANUFACTURER => $BiosManufacturer,
      BVERSION => $BiosVersion,
      BDATE => $BiosDate,
    });

  $inventory->setHardware({

      PROCESSORT => $processort,
      PROCESSORN => $processorn,
      PROCESSORS => $processors

    });


}

1;