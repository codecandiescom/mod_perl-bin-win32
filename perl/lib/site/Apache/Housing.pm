############################################################################
#
# Apache::Housing
# Subroutines for the DRLH Housing system
# Copyright(c) 1998 Texas A&M University
# Author: Jeffrey William Baker (jeff@godzilla.tamu.edu)
# 
############################################################################

package Apache::Housing;

$Apache::Housing::VERSION = '0.01';

use strict;

use DBI;
use Apache;
use Apache::DBI;
use Apache::Constants qw(:response);
use Apache::Session;
use Apache::Session::Win32;

sub new {
  my $class = shift;
  my $self = {};
  
  bless $self, $class;
  
  my $r = Apache->request();
  $self->{'r'} = $r;
  
  return $self;
}

sub get_session {
  my $self = shift;
  my $r = $self->{'r'};

  my $session_id = $r->path_info;
  $session_id =~ s/^\///g;

  my $session = Apache::Session::Win32->open($session_id);

  #If we don't get a session for some reason, redirect to an error document
  if ( !$session ) {
    $r->internal_redirect_handler( "/housing/errors/session.perl" );
    return undef, SERVER_ERROR;
  }

  $self->{'session'} = $session;
  return $session, undef;
}

sub new_session {
  my $self = shift;
  my $r = $self->{'r'};
  
  my $session = Apache::Session::Win32->new();
  
  #If we don't get a session for some reason, redirect to an error document
  if ( !$session ) {
    $r->log_error( "Unable to create new session" );
    $r->internal_redirect_handler( "/housing/errors/session.perl" );
    return undef, SERVER_ERROR;
  }

  $self->{'session'} = $session;
  return $session, undef;
}


sub header {
  my $self = shift;
  my $status = shift;
  my $r = $self->{'r'};
  
  $r->content_type("text/html");
  $r->status( $status );
  $r->no_cache(1);
  $r->send_http_header;
  
  return $status;
}

sub logged_in {
  my $self = shift;
  my $session = $self->{'session'};
  my $r = $self->{'r'};

  unless ( $session->{'authentic'} == 1 ) {
    my $bad_man = $r->get_remote_host();
    $r->log_error( "An attempt was made by $bad_man to access a secure page without logging in." );
    $r->internal_redirect_handler( '/housing/errors/security.perl?major=login' );
    return undef; #this is convenient, but really I should return undef
  }
  return 1;
}

sub safe_connect {
  my $self = shift;
  my $session = $self->{'session'};
  my $r = $self->{'r'};
  my $dbh;
  
  eval {
    local $SIG{__DIE__}; 
    $dbh = DBI->connect($ENV{'ORACLE_DATA_SOURCE'}, $ENV{'ORACLE_USERNAME'}, $ENV{'ORACLE_PASSWORD'}, {
      PrintError => 0,
      AutoCommit => 0
    }) || die $DBI::errstr; 
  };

  if ($@) {
    $r->log_error( "Database connection error: $@" );
    $r->internal_redirect_handler( "/housing/errors/internal.perl?major=Database&text=$@" );
    return undef, SERVER_ERROR;
  }

  return $dbh, undef;
}

sub db_error {
  my $self = shift;
  my $error = shift;

  $self->{'r'}->log_error( "Database error: $error" );
  $self->{'r'}->internal_redirect_handler( "/housing/errors/internal.perl?major=Database&text=$@" );

  return SERVER_ERROR;
}

1;