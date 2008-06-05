package EnsEMBL::Web::Controller::Command::Account::RemoveInvitation;

use strict;
use warnings;

use Class::Std;
use CGI;

use EnsEMBL::Web::Data::Group;

use base 'EnsEMBL::Web::Controller::Command::Account';

{

sub BUILD {
  my ($self, $ident, $args) = @_; 
  $self->add_filter('EnsEMBL::Web::Controller::Command::Filter::LoggedIn');
  my $cgi = new CGI;
  $self->add_filter('EnsEMBL::Web::Controller::Command::Filter::Admin', {'group_id' => $cgi->param('group_id')});
}

sub render {
  my ($self, $action) = @_;
  $self->set_action($action);
  if ($self->not_allowed) {
    $self->render_message;
  } else {
    $self->process;
  }
}

sub process {
  my $self = shift;
  my $cgi = new CGI;
  my $invitation = EnsEMBL::Web::Data::Record::Invite::Group->new($cgi->param('id'));
  $invitation->destroy;
  $cgi->redirect($self->url('/Account/Group', {'id' => $cgi->param('group_id')}) );
}

}

1;
