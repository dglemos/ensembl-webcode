package EnsEMBL::Web::Command::Account::Interface::Bookmark;

use strict;
use warnings;

use EnsEMBL::Web::Data::User;
use EnsEMBL::Web::Data::Group;
use base qw(EnsEMBL::Web::Command);

sub process {
  my $self = shift;
  my $object = $self->object;
  my $data;

  ## Create interface object, which controls the forms
  my $interface = $self->interface;

  ## TODO: make new constructor accept 'record_type' parameter 
  if ($object->param('record_type') && $object->param('record_type') eq 'group') {
    $data = new EnsEMBL::Web::Data::Record::Bookmark::Group($object->param('id'));
  } else {
    $data = new EnsEMBL::Web::Data::Record::Bookmark::User($object->param('id'));
  }
  
  $interface->data($data);
  $interface->discover;

  ## Customization
  $interface->caption({'add'=>'Create bookmark'});
  $interface->caption({'edit'=>'Edit bookmark'});
  $interface->permit_delete('yes');
  $interface->option_columns([qw/name description url/]);
  $interface->modify_element('url', {'type'=>'String', 'label'=>'The URL of your bookmark'});
  $interface->modify_element('name', {'type'=>'String', 'label'=>'Bookmark name'});
  $interface->modify_element('description', {'type'=>'String', 'label'=>'Short description'});
  $interface->modify_element('click', {'type'=>'Hidden'});
  $interface->modify_element('owner_type',  { type => 'Hidden'});
  $interface->element_order([qw/name description url owner_type click/]);

  ## Render page or munge data, as appropriate
  $interface->configure($self->page, $object);
}

1;
