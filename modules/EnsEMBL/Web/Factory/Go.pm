package EnsEMBL::Web::Factory::Go;
                                                                                   
use strict;
use warnings;
no warnings "uninitialized";
                                                                                   
use base qw(EnsEMBL::Web::Factory);

sub createObjects { 
  my $self   = shift;
  
  my $acc_id = $self->param('acc') || $self->param('display');
  my $query = $self->param('query');
  my $limit = $self->param('limit') || 5;

  # Get databases
  my $db  = $self->database('core');
  unless ($db){
    $self->problem( 'Fatal', 'Database Error', "Could not connect to the core database." ); 
    return ;
  }      

  my $ga  = $self->database('go');
  unless ($ga){
    $self->problem( 'Fatal', 'Database Error', "Could not connect to the GO database." ); 
    return ;
  }      

  my $ca  = $self->database('compara');
  unless ($ca){
    $self->problem( 'Fatal', 'Database Error', "Could not connect to the compara database." );
    return ;
  }      
  my $fa = $ca->get_FamilyAdaptor;

  my ($terms, $graph, %families);
  my $flag = 0;
  if ($acc_id || $query) {
    if ($acc_id=~/^(GO:\d+)/i) {
      $acc_id = uc($1);
      $terms    = $ga->get_terms({'acc'=>$acc_id});
      if( @$terms ) {
        $graph   = $ga->get_graph_by_terms( $terms, $limit);
      } else {
        $flag = 1;
      }
    } elsif( ($query =~ /^GO:(\d+)/i) || ($query =~ /^(\d+)$/) ){
      $query = uc( $1 );
      $terms = $ga->get_terms({'acc'=>"GO:$query"});
      if( @$terms ) {
        $acc_id = $query;
        $graph   = $ga->get_graph_by_terms( $terms, $limit);
      } else {
        $flag = 1;
      }
    } elsif( $query ) {
      $terms  = $ga->get_terms({'search'=>$query});
      if( @$terms ) {
        $graph   = $ga->get_graph_by_terms($terms, $limit);
      } else {
        $flag = 1;
      }
    }
    # get genes associated with this graph
## Let us lazy load this....
  }
  if( $flag == 1 ) {
    $self->problem( 'Non-fatal', 'No results', "Did not find any results for search" );
    return ;
  }
  $self->DataObjects($self->new_object( 
        'Go', 
        {'acc_id'=>$acc_id, 'terms' => $terms, 'graph' => $graph, 'families' => {} }, 
        $self->__data )
    );
 
}


1;

