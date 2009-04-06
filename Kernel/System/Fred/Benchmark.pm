# --
# Kernel/System/Fred/Benchmark.pm
# Copyright (C) 2001-2009 OTRS AG, http://otrs.org/
# --
# $Id: Benchmark.pm,v 1.5 2009-04-06 10:26:30 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package Kernel::System::Fred::Benchmark;

use strict;
use warnings;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.5 $) [1];

=head1 NAME

Kernel::System::Fred::Benchmark

=head1 SYNOPSIS

handle the benchmark data

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Log;

    my $ConfigObject = Kernel::Config->new();
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # get needed objects
    for my $Object (qw(ConfigObject LogObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }
    return $Self;
}

=item DataGet()

Get the data for this fred module. Returns true or false.
And add the data to the module ref.

    $BackendObject->DataGet(
        ModuleRef => $ModuleRef,
    );

=cut

sub DataGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for my $Needed_Ref (qw( ModuleRef )) {
        if ( !$Param{$Needed_Ref} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $Needed_Ref!",
            );
            return;
        }
    }

    my $TableRef = [
        [
            "Can't find the benchmark table, please check your code an read the HOWTO for the benchmark module."
        ]
    ];
    if ( $Self->{ConfigObject}->Get('Benchmark') ) {
        $TableRef = $Self->{ConfigObject}->Get('Benchmark');
    }
    $Param{ModuleRef}->{Data} = $TableRef;

    return 1;
}

=item ActivateModuleTodos()

Do all jobs which are necessary to activate this special module.

    $FredObject->ActivateModuleTodos(
        ModuleName => $ModuleName,
    );

=cut

sub ActivateModuleTodos {
    return 1;
}

=item DeactivateModuleTodos()

Do all jobs which are necessary to deactivate this special module.

    $FredObject->DeactivateModuleTodos(
        ModuleName => $ModuleName,
    );

=cut

sub DeactivateModuleTodos {
    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see http://www.gnu.org/licenses/agpl.txt.

=cut

=head1 VERSION

$Revision: 1.5 $ $Date: 2009-04-06 10:26:30 $

=cut
