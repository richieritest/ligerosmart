# --
# Kernel/Output/HTML/FredHTMLCheck.pm - layout backend module
# Copyright (C) 2001-2008 OTRS AG, http://otrs.org/
# --
# $Id: FredHTMLCheck.pm,v 1.4 2008-05-21 10:11:57 mh Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see http://www.gnu.org/licenses/gpl-2.0.txt.
# --

package Kernel::Output::HTML::FredHTMLCheck;

use strict;
use warnings;

use vars qw(@ISA $VERSION);
$VERSION = qw($Revision: 1.4 $) [1];

=head1 NAME

Kernel::Output::HTML::FredHTMLCheck - layout backend module

=head1 SYNOPSIS

All layout functions of HTML check object

=over 4

=cut

=item new()

create an object

    $BackendObject = Kernel::Output::HTML::FredSTDERRLog->new(
        %Param,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (qw(ConfigObject LogObject LayoutObject)) {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    return $Self;
}

=item CreateFredOutput()

create the output of the STDERR log

    $LayoutObject->CreateFredOutput(
        ModulesRef => $ModulesRef,
    );

=cut

sub CreateFredOutput {
    my ( $Self, %Param ) = @_;

    my $HTMLLines = '';

    # check needed stuff
    if ( !$Param{ModuleRef} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need ModuleRef!',
        );
        return;
    }

    if ( $Param{ModuleRef}->{Data} ) {
        for my $Line ( reverse @{ $Param{ModuleRef}->{Data} } ) {
            $Line = $Self->{LayoutObject}->Ascii2Html( Text => $Line );
            $HTMLLines .= "        <tr><td>$Line</td></tr>\n";
        }

        if ($HTMLLines) {
            $Param{ModuleRef}->{Output} = $Self->{LayoutObject}->Output(
                TemplateFile => 'DevelFredHTMLCheck',
                Data         => {
                    HTMLLines => $HTMLLines,
                },
            );
        }
    }
    return 1;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (http://otrs.org/).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see http://www.gnu.org/licenses/gpl-2.0.txt.

=cut

=head1 VERSION

$Revision: 1.4 $ $Date: 2008-05-21 10:11:57 $

=cut
