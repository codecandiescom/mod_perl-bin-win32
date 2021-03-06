package Apache::ModuleConfig;
use strict;
$Apache::ModuleConfig::VERSION = "0.01";

unless(defined &bootstrap) {
    require DynaLoader;
    @Apache::ModuleConfig::ISA = qw(DynaLoader);
}

if($ENV{MOD_PERL}) {
    __PACKAGE__->bootstrap;
}

sub has_srv_config {
    my $file = (caller)[1];
    if($Apache::ServerStarting == 1) {
	delete $INC{$file};
    }
}

sub dir_merge {
    my($base, $add) = @_;
    my %new = ();
    @new{ keys %$base, keys %$add} = 
	(values %$base, values %$add);

    return bless \%new, ref($base);
}

1;

__END__

