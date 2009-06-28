#!perl -w

use Test::More tests => 7;
use File::Basename;
use Cwd 'abs_path';

BEGIN {
    use_ok( 'Tempest' );
}

SKIP: {
    # skip entire test file if GD module is not available
    eval { require GD };
    skip "GD module not installed", 3 if $@;
    
    # remove output file if it exists
    if(-f dirname(__FILE__) . '/data/output_gd.png') {
        unlink(dirname(__FILE__) . '/data/output_gd.png');
    }
    
    $instance = new Tempest(
        'input_file' => dirname(__FILE__) . '/data/screenshot.png',
        'output_file' => dirname(__FILE__) . '/data/output_gd.png',
        'coordinates' => [
            [205,196],
            [208,205],
            [211,198],
            [218,205],
            [208,205],
            [208,205],
            [208,205],
            [388,201],
            [298,226],
            [369,231],
            [343,225],
            [345,14],
            [345,14],
        ],
        'image_lib' => Tempest::LIB_GD,
        'overlay' => 1
    );
    $result = $instance->render();
    ok($result, 'Render method should return true');
    
    ok(-f dirname(__FILE__) . '/data/output_gd.png', 'Output file should exist');
    
    SKIP: {
        $result = _compare(10, dirname(__FILE__) . '/data/output_gd.png');
        is($result, "0\n", 'Output image should resemble the image we expect');
        
        my $a_test = new Tempest(
            'input_file' => dirname(__FILE__) . '/data/screenshot.png',
            'output_file' => dirname(__FILE__) . '/data/opacity_gd_a.png',
            'image_lib' => Tempest::LIB_GD,
            'coordinates' => [
                [100,100],
                [200,200], [200,200],
                [300,300], [300,300], [300,300],
            ],
        );
        $a_test->render();
        ok(-f dirname(__FILE__) . '/data/opacity_gd_a.png', 'Output file for "a" test should exist');
        
        my $b_test = new Tempest(
            'input_file' => dirname(__FILE__) . '/data/screenshot.png',
            'output_file' => dirname(__FILE__) . '/data/opacity_gd_b.png',
            'image_lib' => Tempest::LIB_GD,
            'coordinates' => [
                [100,100], [100,100],
                [200,200], [200,200], [200,200],
                [300,300], [300,300], [300,300], [300,300],
            ],
        );
        $b_test->render();
        ok(-f dirname(__FILE__) . '/data/opacity_gd_b.png', 'Output file for "b" test should exist');
        
        $result = _compare(
            20,
            dirname(__FILE__) . '/data/opacity_gd_a.png',
            dirname(__FILE__) . '/data/opacity_gd_b.png',
        );
        is($result, "0\n", 'Output images should be mostly identical');
    }
}

sub _compare {
    my $fuzz = shift;
    my $compare = shift;
    my $baseline = shift;
    
    if(!$baseline) {
        $baseline = dirname(__FILE__) . '/data/compare.png';
    }
    
    my $output = `compare -version 2>&1`;
    if(!defined($output) || $output !~ m/Version\:\s*ImageMagick/) {
        skip 'ImageMagick compare utility not available', 4;
        return;
    }
    
    # ensure diff file exists first
    my $diff_file = dirname(__FILE__) . '/data/diff.png';
    if(!-f $diff_file) {
        open(my $TOUCH, '>', $diff_file);
        close($TOUCH);
    }
    
    $output = 'compare -metric ae -fuzz ' . $fuzz . '% '
        . abs_path($compare)
        . ' '
        . abs_path($baseline)
        . ' '
        . abs_path(dirname(__FILE__) . '/data/diff.png')
        . ' 2>&1';
    return `$output`;
}
