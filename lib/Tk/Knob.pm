package Tk::Knob;


use 5.006;
use strict;
use warnings;

=encoding UTF-8

=head1 NAME

Tk::Knob - A Knob Tk widget that can turn indefinitely in any direction.

=head1 VERSION

Version 0.001

=cut

$Tk::Knob::VERSION=0.001;

=head1 SYNOPSIS

    use Tk;
    use Tk::Knob;
    my $value=0;
    my $svalue="";
    my $mw=Tk::MainWindow->new(-title=>"Knob test");
    my $kf=$mw->Frame->pack;
    $kf->Knob( -width=>100, 
               -height=>100,
	       -knobsize=>49, 
	       -knobrovariable=>\$v,
	       -knobcommand=>\&cmd,
    )->pack->createKnob;

    sub cmd {
	$value=$v;
	$svalue=sprintf "Value: %.2f Hz", $value;
	$svalue.=" OUT OF RANGE (0-10)", if $value>10 or $value < 0;
	$value=0 if $value<0;
	$value=10 if $value > 10;
    }  
    
Creates a circular Knob that can be turned continuously and
indefinitely in any direction 

=head1 DESCRIPTION

Knob Widget that allows the creation of circular knobs that can turn
indefinitely to produce arbitrary positive or negative values.

=head1 FUNCTIONS


=head2 Knob

Make a Knob object and pass it initialization parameters. They may
also be set and interrogated with Tk's 'configure' and 'cget'.

=head 3 Parameters (defaults)
=over 4

=item -width (500)

=item -height (500)

=item -knobsize (250)
 
=item -knobvalue (0)

=item -knobcolor ('DarkGrey')

=item -knobborder (2)

=item -knobbordercolor1 ('grey38')

=item -knobbordercolor2 ('grey99')

=item -knobrovariable (undef)

=item -knobcommand (sub {return})

=back

=head2 createKnob

Displays the knob, sets its initial parameters, binds the callback
routines. 

=head2 Not to be called by the user directly

=head3 ClassInit

Calls the base class initializer

=head3 Populate

Sets default values for the class parameters.

=head3 pushed

Routine called when button 1 is pushed

=head3 rotate

Routine called to rotate knob when the mouse moves

=head1 AUTHOR

W. Luis Mochán, Instituto de Ciencias Físicas, UNAM, México
C<mochan@fis.unam.mx> 

=head1 ACKNOWLEDGMENTS

This work was partially supported by DGAPA-UNAM under grants IN108413
and IN113016.   

=cut


use constant {
    PI=>4*atan2(1,1),
    id=>0.85, # indicator distance from center
    ir=>0.05,  # indicator radius
};

use base qw/Tk::Derived Tk::Canvas/;
use strict;
use warnings;

Construct Tk::Widget 'Knob';


sub ClassInit {
    my($class, $mw) = @_;
    $class->SUPER::ClassInit($mw);
}

sub Populate {
    my($self, $args)=@_;
    my %args=%$args;
    $self->SUPER::Populate($args);
    #$self->Advertise();
    $self->ConfigSpecs(
	-width => [qw(SELF width Width), 500],
	-height=> [qw(SELF heigh Height), 500],
	-knobsize=>[qw(PASSIVE knobsize Knobsize), 250],
	-knobvalue=>[qw(PASSIVE knobvalue Knobvalue), 0],
	-knobcolor=>[qw(PASSIVE knobcolor Knobcolor), 'DarkGrey'],
	-knobborder=>[qw(PASSIVE knobborder Knobborder), 2],
	-knobbordercolor1=>[qw(PASSIVE knobbordercolor1 Knobbordercolor1), 
			    'grey38'],
	-knobbordercolor2=>[qw(PASSIVE knobbordercolor2 Knobbordercolor2), 
			    'grey99'],
	-knobrovariable=>[qw(PASSIVE knobrovariable Knobrovariable), undef],
	-knobcommand=>[qw(CALLBACK knobbordercolor2 Knobbordercolor2), 
		       sub {return}],
	DEFAULT => ['SELF']
	);
    $self->Delegates();
}

sub createKnob {
    my ($self)=@_;
    my $ks=$self->cget(-knobsize);
    my $kc=$self->cget(-knobcolor);
    my $w=$self->cget(-width);
    my $h=$self->cget(-height);
    my $kb=$self->cget(-knobborder);
    my $kbc1=$self->cget(-knobbordercolor1);
    my $kbc2=$self->cget(-knobbordercolor2);
    $self->configure(-knobvalue=>${$self->cget(-knobrovariable)}) 
	if ref $self->cget(-knobrovariable);
    my $a=2*PI*$self->cget(-knobvalue);
    my $ca=cos($a);
    my $sa=sin($a);
    $self->create('oval', $w/2-$ks, $h/2-$ks, $w/2+$ks, $h/2+$ks,
		  -fill=>$kc, -width=>0, -tags=>[qw(knob)]); 
    $self->create('arc', $w/2-$ks, $h/2-$ks, $w/2+$ks, $h/2+$ks,
		  -style=>'arc', -start=>-135, -extent=>180, -width=>$kb,
		  -outline=>$kbc1 ); 
    $self->create('arc', $w/2-$ks, $h/2-$ks, $w/2+$ks, $h/2+$ks,
		  -style=>'arc', -start=>45, -extent=>180, -width=>$kb,
		  -outline=>$kbc2); 
    $self->create('arc', $w/2+(id*$ca-ir)*$ks, $h/2+(id*$sa-ir)*$ks,
		  $w/2+(id*$ca+ir)*$ks, $h/2+(id*$sa+ir)*$ks, 
		  -style=>'pie', -start=>-135, -extent=>180,
		  -fill=>$kbc2, -outline=>undef, -tags=>[qw(knob indicator)]); 
    $self->create('arc', $w/2+(id*$ca-ir)*$ks, $h/2+(id*$sa-ir)*$ks,
		  $w/2+(id*$ca+ir)*$ks, $h/2+(id*$sa+ir)*$ks, 
		  -style=>'pie', -start=>45, -extent=>180,
		  -fill=>$kbc1, -outline=>undef, -tags=>[qw(knob indicator)]); 
    $self->bind("knob", '<1>', [\&pushed, Tk::Ev('x'), Tk::Ev('y')]);
    $self->bind("knob", '<B1-Motion>', [\&rotate, Tk::Ev('x'), Tk::Ev('y')]);
    return $self;
}

sub pushed {
    my ($self, $x, $y)=@_;
    $self->{angle}=atan2($y-$self->cget(-height)/2, $x-$self->cget(-width)/2);
}

sub rotate {
    my ($self, $x, $y)=@_;
    my $angle=atan2($y-$self->cget(-height)/2, $x-$self->cget(-width)/2);
    my $angle0=$self->{'angle'};
    my $ks=$self->cget(-knobsize);
    $angle-=2*PI while $angle-$angle0>PI;
    $angle+=2*PI while $angle-$angle0<=-PI;
    my $kangle=2*PI*$self->cget(-knobvalue);
    my $nkangle=$kangle+$angle-$angle0;
    my $nval=$nkangle/(2*PI);
    $self->configure(-knobvalue=>$nval);
    ${$self->cget(-knobrovariable)}=$nval if ref $self->cget(-knobrovariable);
    my $deltax=id*$ks*cos($nkangle)-id*$ks*cos($kangle);
    my $deltay=id*$ks*sin($nkangle)-id*$ks*sin($kangle);
    $self->{angle}=$angle;
    $self->move('indicator', $deltax, $deltay);
    $self->Callback(-knobcommand=> $self->cget(-knobvalue));
    #my $command=$self->cget(-knobcommand);
    #$command->($self) if defined $command;
}


1;

