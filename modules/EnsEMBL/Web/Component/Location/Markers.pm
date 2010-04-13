package EnsEMBL::Web::Component::Location::Markers;

use strict;
use warnings;
no warnings "uninitialized";

use base qw(EnsEMBL::Web::Component);

sub _init {
  my $self = shift;
  $self->ajaxable(0);
}

sub content {
	my $self = shift;
  
	my $location = $self->object;
  my $hub = $self->model->hub;
	my $threshold = 1000100 * ($hub->species_defs->ENSEMBL_GENOME_SIZE||1);
		
  return $self->_warning('Region too large', '<p>The region selected is too large to display in this view</p>') if $location->length > $threshold;
    
  my @found_mf = $location->sorted_marker_features($location->Obj->{'slice'});
  my ($html, %mfs);
  
	foreach my $mf (@found_mf) {
		my $name = $mf->marker->display_MarkerSynonym->name;
		my $sr_name = $mf->seq_region_name;
		my $cs = $mf->coord_system_name;
    
		push @{$mfs{$name}->{$sr_name}}, {
      'cs'    => $cs,
      'mf'    => $mf,
      'start' => $mf->seq_region_start,
      'end'   => $mf->seq_region_end
    };
	}
 
  my $c = scalar keys %mfs; 
	$html = "
      <h3>$c mapped markers found:</h3>
      <table>
  ";
    
	foreach my $name (sort keys %mfs) {
	  my ($link, $r);
      
	  foreach my $chr (keys %{$mfs{$name}}) {
		  $link .= "<td><strong>$mfs{$name}->{$chr}[0]{'cs'} $chr:</strong></td>";
        
		  foreach my $det (@{$mfs{$name}->{$chr}}) {
				$link .= "<td>$det->{'start'}-$det->{'end'}</td>";
				$r = "$chr:$det->{'start'}-$det->{'end'}";
			}
	  }
      
    my $url = $hub->url({ type => 'Marker', action => 'Details',  m => $name, r => $r });
      
	  $html .= qq{<tr><td><a href="$url">$name</a></td>$link</tr>};
	}
    
	$html .= '</table>';
  return $html;
}

1;
