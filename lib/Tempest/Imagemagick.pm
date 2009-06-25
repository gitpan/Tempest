package Tempest::Imagemagick;

use strict;
use warnings;

use Carp;
use Image::Magick;

sub render {
    my $parent = shift;
    
    # load source image (in order to get dimensions)
    my $input_file = Image::Magick->new;
    $input_file->Read($parent->get_input_file());
    
    # create object for destination image
    my $output_file = Image::Magick->new;
    $output_file->Set( 'size' => join('x', $input_file->Get('width', 'height')) );
    $output_file->ReadImage('xc:white');
    
    # do any necessary preprocessing & transformation of the coordinates
    my $coordinates = $parent->get_coordinates();
    my $max_rep = 0;
    my %normal;
    for my $pair (@{$coordinates}) {
        # normalize repeated coordinate pairs
        my $pair_key = $pair->[0] . 'x' . $pair->[1];
        if(exists $normal{$pair_key}) {
            $normal{$pair_key}->[2]++;
        }
        else {
            $normal{$pair_key} = [$pair->[0], $pair->[1], 1];
        }
        # get the max repitition count of any single coord set in the data
        if($normal{$pair_key}->[2] > $max_rep) {
            $max_rep = $normal{$pair_key}->[2];
        }
    }
    $coordinates = [ values(%normal) ];
    undef %normal;
    
    # load plot image (presumably greyscale)
    my $plot_file = Image::Magick->new;
    $plot_file->Read($parent->get_plot_file());
    # calculate coord correction based on plot image size
    my @plot_correct = ( ($plot_file->Get('width') / 2), ($plot_file->Get('height') / 2) );
    
    # paste as many plots for each coordinate pair as their repitition indicates
    for my $pair (@{$coordinates}) {
        # apply colorization by how many times coord pair was repeated
        my $point_file = $plot_file->Clone();
        $point_file->Colorize('fill' => 'white', 'opacity' => int((99 * $pair->[2]) / $max_rep) . '%');
        # multiply into output image
        $output_file->Composite('image' => $point_file, 'compose' => 'Multiply', 'x' => ($pair->[0] - $plot_correct[0]), 'y' => ($pair->[1] - $plot_correct[1]) );
    }
    
    # open given spectrum
    my $color_file = Image::Magick->new;
    $color_file->Read($parent->get_color_file());
    
    # apply color lookup table
    $output_file->Clut('image' => $color_file);
    
    # overlay heatmap over source image
    if($parent->get_overlay()) {
        $input_file->Composite('image' => $output_file, 'compose' => 'Blend', 'blend' => $parent->get_opacity() . '%');
        undef $output_file;
        $output_file = $input_file;
    }
    
    # write destination image
    $output_file->Write($parent->get_output_file());
    
    # return true if successful
    return 1;
}

1;
