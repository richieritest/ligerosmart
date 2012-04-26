# --
# OTRSMasterSlave.pm - code to excecute during package installation
# Copyright (C) 2003-2012 OTRS AG, http://otrs.com/
# --
# $Id: OTRSMasterSlave.pm,v 1.8 2012-04-26 12:36:28 te Exp $
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (AGPL). If you
# did not receive this file, see http://www.gnu.org/licenses/agpl.txt.
# --

package var::packagesetup::OTRSMasterSlave;

use strict;
use warnings;

use Kernel::Config;
use Kernel::System::SysConfig;
use Kernel::System::State;
use Kernel::System::Valid;
use Kernel::System::DynamicField;
use Kernel::System::VariableCheck qw(:all);
use Kernel::System::Package;

use vars qw($VERSION);
$VERSION = qw($Revision: 1.8 $) [1];

=head1 NAME

OTRSMasterSlave.pm - code to excecute during package installation

=head1 SYNOPSIS

Functions for installing the OTRSMasterSlave package.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::Time;
    use Kernel::System::DB;
    use var::packagesetup::OTRSMasterSlave;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject    = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $TimeObject = Kernel::System::Time->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $CodeObject = var::packagesetup::OTRSMasterSlave->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
        TimeObject   => $TimeObject,
        DBObject     => $DBObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for my $Object (
        qw(ConfigObject EncodeObject LogObject MainObject TimeObject DBObject)
        )
    {
        $Self->{$Object} = $Param{$Object} || die "Got no $Object!";
    }

    # create needed sysconfig object
    $Self->{SysConfigObject} = Kernel::System::SysConfig->new( %{$Self} );

    # rebuild ZZZ* files
    $Self->{SysConfigObject}->WriteDefault();

    # define the ZZZ files
    my @ZZZFiles = (
        'ZZZAAuto.pm',
        'ZZZAuto.pm',
    );

    # reload the ZZZ files (mod_perl workaround)
    for my $ZZZFile (@ZZZFiles) {

        PREFIX:
        for my $Prefix (@INC) {
            my $File = $Prefix . '/Kernel/Config/Files/' . $ZZZFile;
            next PREFIX if !-f $File;
            do $File;
            last PREFIX;
        }
    }

    # create additional objects
    $Self->{ConfigObject}       = Kernel::Config->new();
    $Self->{StateObject}        = Kernel::System::State->new( %{$Self} );
    $Self->{ValidObject}        = Kernel::System::Valid->new( %{$Self} );
    $Self->{DynamicFieldObject} = Kernel::System::DynamicField->new( %{$Self} );
    $Self->{PackageObject}      = Kernel::System::Package->new( %{$Self} );

    # get dynamic fields list
    $Self->{DynamicFieldsList} = $Self->{DynamicFieldObject}->DynamicFieldListGet(
        Valid      => 0,
        ObjectType => ['Ticket'],
    );

    if ( !IsArrayRefWithData( $Self->{DynamicFieldsList} ) ) {
        $Self->{DynamicFieldsList} = [];
    }

    # create a dynamic field lookup table (by name)
    DYNAMICFIELD:
    for my $DynamicField ( @{ $Self->{DynamicFieldsList} } ) {
        next DYNAMICFIELD if !$DynamicField;
        next DYNAMICFIELD if !IsHashRefWithData($DynamicField);
        next DYNAMICFIELD if !$DynamicField->{Name};
        $Self->{DynamicFieldLookup}->{ $DynamicField->{Name} } = $DynamicField;
    }

    return $Self;
}

=item CodeInstall()

run the code install part

    my $Result = $CodeObject->CodeInstall();

=cut

sub CodeInstall {
    my ( $Self, %Param ) = @_;

    # if we got an installed version of MasterSlave, migrate the data
    # otherwise set the dynamic fields
    if ( $Self->{PackageObject}->PackageIsInstalled( Name => 'MasterSlave' ) ) {
        $Self->_MigrateMasterSlave();
        $Self->{PackageObject}->RepositoryRemove( Name => 'MasterSlave' );
    }
    else {
        $Self->_SetDynamicFields();
    }

    return 1;
}

=item CodeReinstall()

run the code reinstall part

    my $Result = $CodeObject->CodeReinstall();

=cut

sub CodeReinstall {
    my ( $Self, %Param ) = @_;

    return 1;
}

=item CodeUpgrade()

run the code upgrade part

    my $Result = $CodeObject->CodeUpgrade();

=cut

sub CodeUpgrade {
    my ( $Self, %Param ) = @_;

    # upgrade/migrate only in case there is a installed
    # version of OTRSMasterSlave version < 1.2.5
    $Self->_MigrateMasterSlave();

    return 1;
}

=item CodeUninstall()

run the code uninstall part

    my $Result = $CodeObject->CodeUninstall();

=cut

sub CodeUninstall {
    my ( $Self, %Param ) = @_;

    return 1;
}

sub _SetDynamicFields {
    my ( $Self, %Param ) = @_;

    # get dynamic field names from sysconfig
    my $MasterSlaveDynamicField
        = $Self->{ConfigObject}->Get('MasterSlave::DynamicField');

    # set attributes of new dynamic fields
    my %NewDynamicFields = (
        $MasterSlaveDynamicField => {
            Name       => $MasterSlaveDynamicField,
            Label      => 'Master Ticket',
            FieldType  => 'Dropdown',
            ObjectType => 'Ticket',
            Config     => {
                DefaultValue   => '',
                PossibleValues => {
                    Master => 'New Master Ticket',
                },
                TranslatableValues => 1,
            },
        },
    );

    # set MaxFieldOrder (needed for adding new dynamic fields)
    my $MaxFieldOrder = 0;
    if ( !IsArrayRefWithData( $Self->{DynamicFieldsList} ) ) {
        $MaxFieldOrder = 1;
    }
    else {
        DYNAMICFIELD:
        for my $DynamicFieldConfig ( @{ $Self->{DynamicFieldsList} } ) {
            if ( int $DynamicFieldConfig->{FieldOrder} > int $MaxFieldOrder ) {
                $MaxFieldOrder = $DynamicFieldConfig->{FieldOrder}
            }
        }
    }

    for my $NewFieldName ( keys %NewDynamicFields ) {

        # check if dynamic field already exists
        if ( IsHashRefWithData( $Self->{DynamicFieldLookup}->{$NewFieldName} ) ) {

            # get the dynamic field configuration
            my $DynamicFieldConfig = $Self->{DynamicFieldLookup}->{$NewFieldName};

            # if dynamic field exists make sure is valid
            if ( $DynamicFieldConfig->{ValidID} ne '1' ) {

                my $Success = $Self->{DynamicFieldObject}->DynamicFieldUpdate(
                    %{$DynamicFieldConfig},
                    ValidID => 1,
                    Reorder => 0,
                    UserID  => 1,
                );

                if ( !$Success ) {
                    $Self->{LogObject}->Log(
                        Priority => 'error',
                        Message  => "Could not set dynamic field '$NewFieldName' to valid!",
                    );
                }
            }
        }

        # otherwise create it
        else {
            $MaxFieldOrder++;
            my $ID = $Self->{DynamicFieldObject}->DynamicFieldAdd(
                %{ $NewDynamicFields{$NewFieldName} },
                FieldOrder => $MaxFieldOrder,
                ValidID    => 1,
                UserID     => 1,
            );

            if ( !$ID ) {
                $Self->{LogObject}->Log(
                    Priority => 'error',
                    Message  => "Could not add dynamic field '$NewFieldName'!",
                );
            }
        }
    }

    # enable dynamic field for ticket zoom
    # get old configuration
    my $WindowConfig = $Self->{ConfigObject}->Get('Ticket::Frontend::AgentTicketZoom');
    my %DynamicFields = %{ $WindowConfig->{DynamicField} || {} };

    $DynamicFields{$MasterSlaveDynamicField} =
        defined $DynamicFields{$MasterSlaveDynamicField}
        ? $DynamicFields{$MasterSlaveDynamicField}
        : 1;

    $Self->{SysConfigObject}->ConfigItemUpdate(
        Valid => 1,
        Key   => 'Ticket::Frontend::AgentTicketZoom###DynamicField',
        Value => \%DynamicFields,
    );

    return 1;
}

sub _MigrateMasterSlave {
    my ( $Self, %Param ) = @_;

    # get dynamic field names from sysconfig
    my $MasterSlaveDynamicField = $Self->{ConfigObject}->Get('MasterSlave::DynamicField')
        || 'MasterSlave';

    # check if there isn't allready a dynamic field with the destinated name
    return 1 if IsHashRefWithData( $Self->{DynamicFieldLookup}->{$MasterSlaveDynamicField} );

    # get the migrated field ID by searching for possible data
    $Self->{DBObject}->Prepare(
        SQL => "SELECT dfv.field_id FROM dynamic_field_value dfv "
            . "WHERE dfv.value_text LIKE 'SlaveOf:%' OR dfv.value_text = 'Master'",
        Limit => 1,
    );

    my $OldMasterSlaveDynamicFieldID;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $OldMasterSlaveDynamicFieldID = $Row[0];
    }

    # check if we found a valid ID
    return 0 if !$OldMasterSlaveDynamicFieldID;

    # try to get the dynfield data (for fieldorder etc.)
    my $OldDynamicField = $Self->{DynamicFieldObject}->DynamicFieldGet(
        ID => $OldMasterSlaveDynamicFieldID,
    );

    return 0 if !IsHashRefWithData($OldDynamicField);

    # update the name of the dynamic field to MasterSlave and store it
    # and return the result of this function
    return 0 if !$Self->{DynamicFieldObject}->DynamicFieldUpdate(
        %{$OldDynamicField},
        Name      => $MasterSlaveDynamicField,
        Label     => 'Master Ticket',
        FieldType => 'Dropdown',
        Config    => {
            DefaultValue   => '',
            PossibleValues => {
                Master => 'New Master Ticket',
            },
            TranslatableValues => 1,
        },
        ValidID => 1,
        Reorder => 0,
        UserID  => 1,
    );

    # activate the DynamicField in ticket details block
    my $KeyString       = "Ticket::Frontend::AgentTicketZoom";
    my $ExistingSetting = $Self->{ConfigObject}->Get($KeyString) || {};
    my %ValuesToSet     = %{ $ExistingSetting->{DynamicField} || {} };
    $ValuesToSet{MasterSlave} = 1;
    return $Self->{ConfigObject}->ConfigItemUpdate(
        Valid => 1,
        Key   => $KeyString . "###DynamicField",
        Value => \%ValuesToSet,
    );
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<http://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (AGPL). If you
did not receive this file, see L<http://www.gnu.org/licenses/agpl.txt>.

=cut

=head1 VERSION

$Revision: 1.8 $ $Date: 2012-04-26 12:36:28 $

=cut
