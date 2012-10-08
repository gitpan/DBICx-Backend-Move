package DBICx::Backend::Move;

use 5.010;
use strict;
use warnings;
use Moo;
use Module::Load 'load';
use DBICx::Deploy;


sub deploy
{
        my ( $self, $schema, $dsn, @args ) = @_;
        load $schema;
        DBICx::Deploy->deploy($schema, $dsn, @args);
        return;
}


sub transfer_data
{
        my ( $self, $from, $to, $verbose ) = @_;

        $verbose ||= 0;
 SOURCE:
        foreach my $source_name ($from->sources) {
                print STDERR "Transfer: $source_name => " if $verbose;
                my $source_rs = $from->resultset($source_name);

                if (ref $source_rs->result_source eq 'DBIx::Class::ResultSource::View') {
                        say STDERR "$source_name is a view. Skipped." if $verbose;
                        next SOURCE;
                }

                # prepare rows, so we don't need to call columns in the following loop
                my @rownames = $source_rs->result_source->columns;

                while (my $row = $source_rs->next) {
                        my %source_row;
                        print STDERR "." if $verbose >= 2;
                        foreach my $column (@rownames) {
                                $source_row{$column} = $row->$column;
                        }
                        my $new_row = $to->resultset($source_name)->new(\%source_row);
                        $new_row->insert;
                }
                print STDERR "done.\n" if $verbose;
        }
        return;
}

1;