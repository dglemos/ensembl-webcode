package Bio::EnsEMBL::GlyphSet::Psuperfamily;
use strict;
use vars qw(@ISA);
use Bio::EnsEMBL::GlyphSet;
@ISA = qw(Bio::EnsEMBL::GlyphSet);
use Sanger::Graphics::Glyph::Rect;
use Sanger::Graphics::Glyph::Text;
use Sanger::Graphics::Glyph::Composite;
use  Sanger::Graphics::Bump;

sub init_label {
    my ($self) = @_;
	return if( defined $self->{'config'}->{'_no_label'} );
    my $label = new Sanger::Graphics::Glyph::Text({
	'text'      => 'SCOP Superfamily',
	'font'      => 'Small',
	'absolutey' => 1,
    });
    $self->label($label);
}

sub _init {
    my ($self) = @_;

    my $Config        = $self->{'config'};
    my $protein       = $self->{'container'};
    $protein->dbID || return; # Non-database translation

    my %hash;
    my $y             = 0;
    my $h             = 4;
    my @bitmap        = undef;
    my $pix_per_bp    = $Config->transform->{'scalex'};
    my $bitmap_length = int($protein->length() * $pix_per_bp);
    my $colour        = $Config->get('Psuperfamily','col');
    my $font          = "Small";
    my ($fontwidth, $fontheight)  = $Config->texthelper->real_px2bp($font);

    my @ps_feat = @{$protein->get_all_ProteinFeatures('superfamily')};
    foreach my $feat(@ps_feat) {
	    push(@{$hash{$feat->hseqname}},$feat);
    }
    
#    my $PID = $self->{'container'}->id;
    foreach my $key (keys %hash) {
	my @row = @{$hash{$key}};
       	my $desc = $row[0]->idesc();
        my $KK = $key;
	my $Composite = new Sanger::Graphics::Glyph::Composite({
	    'x' => $row[0]->start(),
	    'y' => 0,
	    'href' => $self->ID_URL('SUPERFAMILY',$KK) ,
        'zmenu' => { "SCOP: $KK" => $self->ID_URL('SUPERFAMILY',$KK) },
	});

	my $prsave;
	my ($minx, $maxx);

	foreach my $pr (@row) {
	    my $x  = $pr->start();
	    $minx  = $x if ($x < $minx || !defined($minx));
	    my $w  = $pr->end() - $x;
	    $maxx  = $pr->end() if ($pr->end() > $maxx || !defined($maxx));
	    my $id = $pr->hseqname();
	    
	    my $rect = new Sanger::Graphics::Glyph::Rect({
		'x'        => $x,
		'y'        => $y,
		'width'    => $w,
		'height'   => $h,
		'colour'   => $colour,
	    });
			
	    $Composite->push($rect);
	    $prsave = $pr;
	}

	#########
	# add a domain linker
	#
	my $rect = new Sanger::Graphics::Glyph::Rect({
	    'x'        => $minx,
	    'y'        => $y + 2,
	    'width'    => $maxx - $minx,
	    'height'   => 0,
	    'colour'   => $colour,
	    'absolutey' => 1,
	});
	$Composite->push($rect);

	#########
	# add a label
	#
	$desc = "SCOP: $KK";
	my $text = new Sanger::Graphics::Glyph::Text({
	    'font'   => $font,
	    'text'   => $desc,
	    'x'      => $minx,
	    'y'      => $h + 1,
	    'height' => $fontheight,
	    'width'  => $fontwidth * length($desc),
	    'colour' => $colour,
            'absolutey' => 1
 	});
 	$Composite->push($text);

	if ($Config->get('Psuperfamily', 'dep') > 0){ # we bump
            my $bump_start = int($Composite->x() * $pix_per_bp);
            $bump_start = 0 if ($bump_start < 0);

            my $bump_end = $bump_start + int($Composite->width() * $pix_per_bp);
            if ($bump_end > $bitmap_length){$bump_end = $bitmap_length};
            my $row = & Sanger::Graphics::Bump::bump_row(      
				      $bump_start,
				      $bump_end,
				      $bitmap_length,
				      \@bitmap
            );
            $Composite->y($Composite->y() + (1.5 * $row * ($h + $fontheight)));
            # $Composite->y($Composite->y() + (2 * $row * ($h )));
        }
	
	$self->push($Composite);
    }
}

1;
