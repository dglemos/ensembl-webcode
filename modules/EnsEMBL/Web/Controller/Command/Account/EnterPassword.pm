package EnsEMBL::Web::Controller::Command::Account::EnterPassword;

use strict;
use warnings;

use Class::Std;
use CGI;

use EnsEMBL::Web::Document::Interface;
use EnsEMBL::Web::Interface::InterfaceDef;

use base 'EnsEMBL::Web::Controller::Command::Account';

{

sub BUILD {
  my ($self, $ident, $args) = @_;
  my $cgi = new CGI;
  if ($cgi->param('code')) {
    $self->add_filter('EnsEMBL::Web::Controller::Command::Filter::ActivationValid');
  }
  else {
    $self->add_filter('EnsEMBL::Web::Controller::Command::Filter::LoggedIn');
  }
}

sub render {
  my ($self, $action) = @_;
  $self->set_action($action);
  if ($self->not_allowed) {
    $self->render_message;
  } else {
    $self->render_page;
  }
}

sub render_page {
  my $self = shift;
 
    my $webpage= new EnsEMBL::Web::Document::WebPage(
    'renderer'   => 'Apache',
    'outputtype' => 'HTML',
    'scriptname' => 'Account/Password',
    'objecttype' => 'Account',
  );

  if( $webpage->has_a_problem() ) {
    $webpage->render_error_page( $webpage->problem->[0] );
  } else {
    foreach my $object( @{$webpage->dataObjects} ) {
      $webpage->configure( $object, 'enter_password', 'global_context', 'local_context' );
    }
    $webpage->render();
  }
}

}

1;
