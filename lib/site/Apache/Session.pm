package Apache::Session;

my $LIFETIME = 3600; #seconds

my %error = (

	"new"     => "Session object not found, created new object",
	"none"    => "No error",
	"timeout" => "Session object expired, created new object"
	
);

my %sessions;

sub new {

	my $package = shift;
	my $this_session = shift;
	my $self;
	
	return 0 unless $this_session;
	
	SWITCH:
	{
	($self = &create_new($this_session, $package, $error{'new'})), last SWITCH unless $sessions{$this_session};
	
	$self = $sessions{$this_session};
	
	($self = &create_new($this_session, $package, $error{'timeout'})), last SWITCH if ($self->{'meta'}->{'expiration_time'} < time());
	
	$self->{'meta'}->{'error_msg'} = $error{'none'};
	}
	
	return $sessions{$this_session};
	
	sub create_new {
	
		my $this_session = shift;
		my $package = shift;
		my $error_msg = shift;
		
		my $self = {};

		$self->{'meta'}->{'id'} = $this_session;
		$self->{'meta'}->{'lifetime'} = $LIFETIME;
		$self->{'meta'}->{'expiration_time'} = time() + $LIFETIME;
		$self->{'meta'}->{'error_msg'} = $error_msg;

		$sessions{$this_session} = $self;
		bless($sessions{$this_session} => $package);	
				
		return $self;

	}

}

sub set {

	my $self = shift;
	my $var_name = shift;
	my $ref_to_value = shift;

	touch($self);

	return 0 if (!$var_name);
	return 0 if (!ref($ref_to_value));

	$self->{'data'}->{$var_name} = $ref_to_value;

	return 1;
	
}

sub read {

	my $self = shift;
	my $var_name = shift;

	touch($self);

	return $self->{'data'}->{$var_name} if (defined $self->{'data'}->{$var_name});
	return 0;
}

sub abandon {

	my $self = shift;
	my $my_id = $self->{'meta'}->{'id'};
	
	delete $sessions{$my_id};
	
	return 1;
	
}

sub lifetime {

	my $self = shift;
	my $new_lifetime = shift;

	if (defined $new_lifetime) {
	
		my $old_lifetime = $self->{'meta'}->{'lifetime'};

		$self->{'meta'}->{'lifetime'} = $new_lifetime;
		$self->{'meta'}->{'expiration_time'} = time() + $new_lifetime;
		
		return $old_lifetime;

	}
	
	else {
	
		return $self->{'meta'}->{'lifetime'};
		
	}
	
}

sub expires {
	
	my $self = shift;
	my $new_exp_time = shift;
	
	my $old_exp_time = $self->{'meta'}->{'expiration_time'};

	if ($new_exp_time) {
			
		$self->{'meta'}->{'expiration_time'} = $new_exp_time;
		
	}
	
	return $old_exp_time;
	
}

sub touch {

	my $self = shift;
	
	$self->{'meta'}->{'expiration_time'} = time() + $self->{'meta'}->{'lifetime'};

	return 1;

}

sub get_id {
	
	my $self = shift;
	
	return $self->{'meta'}->{'id'};
	
}

sub get_error_msg {

	my $self = shift;
	
	return $self->{'meta'}->{'error_msg'};

}

1;