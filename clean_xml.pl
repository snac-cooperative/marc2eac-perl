#!/usr/bin/perl -ni

# Clean up MARC XML before processing by marc2cpf in web based environment so the bad guys can't hack our
# system.

use strict;
use Data::Dumper;
use XML::Twig;

main();
exit();

BEGIN {undef $/;}

# With the shebang -pi or -ni the input magically shows up in $_

sub main
{
    my $t= XML::Twig->new(expand_external_ents => -1, comments => 'drop');
    $t->parse( $_ );
    my $root= $t->root;
    
    if (0)
    {
        # remove_cdata() gets rid of any CDATA. Even though CDATA is unlikely in MARC records, it probably
        # can't hurt anything so this block is disabled for now.

        # $root is a reference, so this sub will change the data in place.
        remove_cdata($root);
    }

    $t->set_doctype(0,0,0,0);
    $t->print;
}

sub remove_cdata
{
    # This sub gets rid of CDATA.
    my $root = $_[0];
    my @para= $root->get_xpath( '//*');
    foreach my $para (@para)
    {
        if ($para->is_cdata())
        {
            $para->delete();
        }
    }                   
}
