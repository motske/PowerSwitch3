#	PowerSwitch III
#
#	PowerSwitch III is Kevin Motschiedler's modification of Felix Mueller's PowerSwitch II 
#	plugin done in accordance with GNU General Public License v 2.0, which continues to  
#	apply to this modified version.  Mr. Mueller's GNU notice below regarding use 
#	and modification of this program are incorporated herein.
#	----------------------------------------------------------------------
#	Modification:	PowerSwitch III extends the functionality of PowerSwitch II by
#			allowing clients that do not have ir/geek ports to trigger an
#			amp via the ir/geek port of a SB Classic or Transporter. E.g.,
#			when a software client such as squeezePlay, squeezeSlave,
#			squeezeLite is powered on, the SB Classic/Transporter ir port 
#			will send low voltage power-on unitl soft-client is powered-off. 
#	-----------------------------------------------------------------------
#	Requirements:	Identify non-SB Classic/Transporter clients that will utilize
#			amp switching by including a "~" in their name--e.g., MasterBdRoom~
#	-----------------------------------------------------------------------
#	Compatability:	So far, no conflicts noted with other plugins.  Specifically confirmed
#			PowerSave plugin continues to work perfectly.
#		
#			Although original plugin designed for use with circuit created
#			and displayed on Mr. Mueller's website:
#			www.gwendesign.com/slimserver/dev_hard_and_software.htm
#			The circuit is not required if your amp/preamp or powerstrip
#			will accept a low watt trigger--e.g., ~3.5 volts instead of usual 12v
#			Confirmed works with Belkin PureAV PF60
#	------------------------------------------------------------------------
#
#
#	Original Author's Comments:
#	Author: Felix Mueller <felix(dot)mueller(at)gwendesign(dot)com>
#
#	Copyright (c) 2003-2007 GWENDESIGN
#	All rights reserved.
#
#	----------------------------------------------------------------------
#	Function:	Turn external Amplifier on and off (works for TP and SB)
#	----------------------------------------------------------------------
#	Technical:	To turn the amplifier on, the left IR jack output goes high.
#			To turn the amplifier off, the left IR jack output goes low.
#
#			AmpSwitch compatibilty mode (do not use for new development)
#			To turn the amplifier on, the plugin switches to
#			 GeekMode(Blaster) causing the right output to go low.
#			To turn the amplifier off, the plugin switches to
#			 GeekMode(Audio) causing the right output to be floating.
#	----------------------------------------------------------------------
#	Installation:
#			- Copy the complete directory into the 'Plugins' directory
#			- Restart SlimServer
#			- Enable PowerSwitchIII in the player interface
#			- Optional: set the $gPowerOffDelay / $powerOnDelay in this file
#	----------------------------------------------------------------------
#	History:
#
#	2013/06/06 	- PowerSwitch III Modification by Kevin Motschiedler
#	2008/10/20 v0.4 - Fix for SC 7.x
#	2008/01/23 v0.3 - Fix headphone out if not used for switching
#			  (i.e. make sure to enable audio if not in use)
#	2007/10/22 v0.2 - SC 7.x compatible
#			- AmpSwitch compatiblity mode (do not use for new development)
#	2007/08/31 v0.1	- Initial version (based on AMPSwitch and PowerSwitch)
#	----------------------------------------------------------------------
#	To do:
#
#	- Multi language
#	- Clean up code
#
#	This program is free software; you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation; either version 2 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	You should have received a copy of the GNU General Public License
#	along with this program; if not, write to the Free Software
#	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
#	02111-1307 USA
#
package Plugins::PowerSwitchIII::Plugin;
use base qw(Slim::Plugin::Base);
use strict;

use Slim::Utils::Log;
use Slim::Utils::Prefs;

# ----------------------------------------------------------------------------
# Global variables
# ----------------------------------------------------------------------------

my $gPowerOnDelay	= 0;	# Delay to turn on amplifier after player has been turned on (in seconds)
my $gPowerOffDelay	= 0;	# Delay to turn off amplifier after player has been turned off (in seconds)

my @PowerSwitchIII_choice = ();

# ----------------------------------------------------------------------------
my $log = Slim::Utils::Log->addLogCategory({
	'category'     => 'plugin.powerswitchiii',
	'defaultLevel' => 'OFF',
	'description'  => 'PLUGIN_POWERSWITCHIII_MODULE_NAME',
});

# ----------------------------------------------------------------------------
my $prefs = preferences('plugin.powerswitchiii');

# ----------------------------------------------------------------------------
sub initPlugin {
	my $class = shift;

	@PowerSwitchIII_choice = (
		{
			'name'  => '{PLUGIN_POWERSWITCHIII_DISABLED}',
			'value' => 0,
		},
		{
			'name'  => '{PLUGIN_POWERSWITCHIII_ENABLED}',
			'value' => 1,
		},
#		{
#			'name'  => '{PLUGIN_POWERSWITCHIII_AMPSWITCH}',
#			'value' => 2,
#		},
	);

	# Install callback to get client power state changes
	Slim::Control::Request::subscribe( \&commandCallback, [['power', 'play', 'playlist', 'pause', 'client']]);

	$class->SUPER::initPlugin();
}

# ----------------------------------------------------------------------------
sub getDisplayName() {
	return( 'PLUGIN_POWERSWITCHIII_MODULE_NAME');
}

# ----------------------------------------------------------------------------
sub setMode {
	my $class  = shift;
	my $client = shift;
	my $method = shift;

	if ($method eq 'pop') {
		Slim::Buttons::Common::popMode($client);
		return;
	}

	# use INPUT.Choice
	my %params = (
		'header'       => '{PLUGIN_POWERSWITCHIII_MODULE_NAME} {count}',
		'listRef'      => \@PowerSwitchIII_choice,
		'modeName'     => 'PowerSwitchIIIChoice',
		'overlayRef'   => \&getSelectedChoiceOverlay,
		'onRight'      => \&setSelectedChoice,
		'initialValue' => \&getSelectedChoiceInitialValue,
	);

	Slim::Buttons::Common::pushMode($client, 'INPUT.Choice', \%params);
}

# ----------------------------------------------------------------------------
sub getSelectedChoiceOverlay {
	my ( $client, $entry) = @_;
	my $rv = '0';

	if( $prefs->client($client)->get( 'enabled') eq $entry->{'value'}) {
		$rv = '1';
	}
	return [undef, Slim::Buttons::Common::checkBoxOverlay( $client, $rv)];
}

# ----------------------------------------------------------------------------
sub setSelectedChoice {
	my ( $client, $entry) = @_;

	$prefs->client($client)->set( 'enabled', $entry->{'value'});
	$client->update;
}

# ----------------------------------------------------------------------------
sub getSelectedChoiceInitialValue {
	my ( $client, $entry) = @_;

	return $prefs->client($client)->get('enabled');
}

# Actual power state (needed for internal tracking)
my %iOldPowerState;
my $irCapableClient;
my $currentSwitchState = 0;

# ----------------------------------------------------------------------------
# Callback to get client power state changes
# ----------------------------------------------------------------------------
sub commandCallback {
	my $request = shift;

	my $client = $request->client();

	$log->debug( "*** PowerSwitchIII: commandCallback() p0: " . $request->{'_request'}[0] . "\n");
	$log->debug( "*** PowerSwitchIII: commandCallback() p1: " . $request->{'_request'}[1] . "\n");
	$log->debug( "*** PowerSwitchIII: commandCallback() client name: " . $client->name() . "\n");
	$log->debug( "*** PowerSwitchIII: commandCallback() client class: " . ref($client) . "\n");

	# Do nothing if client is not defined
	if( !defined( $client)) {
		return;
	}

    # Do nothing if client is not a Transporter, Squeezebox2 or greedy client
    if( !($client->isa( "Slim::Player::Transporter")) && !(ref $client eq "Slim::Player::Squeezebox2") && !($client->name() =~ /~/)) {
        return;		#"needy clients" are identified by including a "~" in their name--e.g., LivingRm~  
    }

    # Hang on to a reference to a device which is IR capable.
    if($client->isa( "Slim::Player::Transporter") || ref $client eq "Slim::Player::Squeezebox2") {
    	$log->debug( "*** PowerSwitchIII: commandCallback() found IR capable client: " . $client->name() . "\n");
        $irCapableClient = $client;
        my $PowerSwitchEnabled = $prefs->client($client)->get( 'enabled');
        $log->debug( "*** PowerSwitchIII: commandCallback() power switch enabled is: " . $PowerSwitchEnabled . "\n");
        
	    # Do nothing if power switch is disabled for the IR capable device
	    if( !defined( $PowerSwitchEnabled) || $PowerSwitchEnabled == 0) {
	        &handlePowerOff( $client);
	        return;
	    }                
    }

	# Get power on and off commands
	# Sometimes we do get only a power command, sometimes only a play/pause command and sometimes both
	if( $request->isCommand([['power']])
	 || $request->isCommand([['play']])
	 || $request->isCommand([['pause']])
	 || $request->isCommand([['playlist'], ['newsong']]) ) {
		my $iPower = $client->power();
		
		# Check with last known power state -> if different switch output
		if( $iOldPowerState{$client} ne $iPower) {
			$iOldPowerState{$client} = $iPower;

			$log->debug("*** PowerSwitchIII: commandCallback() Power: $iPower\n");

			if( $iPower == 1) {
				# If player is turned on within delay, kill delayed power off timer
				Slim::Utils::Timers::killTimers( $irCapableClient, \&handlePowerOff); 

				# Set timer to power on amplifier after a delay
				Slim::Utils::Timers::setTimer( $irCapableClient, (Time::HiRes::time() + $gPowerOnDelay), \&handlePowerOn); 
			} else {
				# Make sure there aren't any other devices on needing the switch
				foreach my $clientHashKey ( keys %iOldPowerState )
                {
                	if($iOldPowerState{$clientHashKey}) {
                        $log->debug("*** PowerSwitchIII: commandCallback() Client:" . $client->name() . " was powered down but another device: " . $clientHashKey . " still needs the switch powered\n");                		
                        return;		
                	}
                }
                
				# If player is turned off within delay, kill delayed power on timer
				Slim::Utils::Timers::killTimers( $irCapableClient, \&handlePowerOn); 

				# Set timer to power off amplifier after a delay
				Slim::Utils::Timers::setTimer( $irCapableClient, (Time::HiRes::time() + $gPowerOffDelay), \&handlePowerOff); 
			}
		}
	# Get newclient events
	} elsif( $request->isCommand([['client'], ['new']])
	      || $request->isCommand([['client'], ['reconnect']])) {
		my $subCmd = $request->{'_request'}[1];
	
		$log->debug("*** PowerSwitchIII: commandCallback() client: $subCmd\n");

		# Get current power state (needed for internal tracking)
		if( !defined( $iOldPowerState{$client})) {
			$iOldPowerState{$client} = $client->power();
		}
	}
}

# ----------------------------------------------------------------------------
sub handlePowerOn {
	my $client = shift;

    if($currentSwitchState) {
    	$log->debug("*** PowerSwitchIII: handlePowerOn Switch alreadyEnabled, skipping IR blast\n");
    	return;
    } else {
        $currentSwitchState = 1;
        $log->debug("*** PowerSwitchIII: handlePowerOn Enabling switch\n");        
    }
    
#	# AmpSwitch compatibilty (do not use for new development)
#	if( $prefs->client($client)->get( 'enabled') eq 2) {
#
#		# Set GeekMode(Blaster)
#		my $geekmode = pack( 'C', 1);
#		$client->sendFrame( 'geek', \$geekmode);
#
#		return;
#	}

	# On means: hightime = 1; lowtime = 1; modulation = 1
	my $ircode = &IRBlastPulse( 1, 1, 1);

	Slim::Utils::Timers::setTimer( $client, Time::HiRes::time() + 0.1, \&IRBlastSendCallback, (\$ircode));
}

# ----------------------------------------------------------------------------
sub handlePowerOff {
	my $client = shift;

    if(! $currentSwitchState) {
        $log->debug("*** PowerSwitchIII: handlePowerOff Switch already powered off, skipping IR blast\n");    	
        return;
    } else {
        $log->debug("*** PowerSwitchIII: handlePowerOff Disabling switch\n");           	
        $currentSwitchState = 0;
    }
    
#	# AmpSwitch compatibilty (do not use for new development)
#	if( ( $prefs->client($client)->get( 'enabled') eq 2) || ( $prefs->client($client)->get( 'enabled') eq 0)) {
#		# Set GeekMode(Audio)
#		my $geekmode = pack( 'C', 0);
#		$client->sendFrame( 'geek', \$geekmode);
#
#		return;
#	}
	
	# Off means: hightime = 1; lowtime = 0; modulation = 1
	my $ircode = &IRBlastPulse( 1, 0, 1);

	Slim::Utils::Timers::setTimer( $client, Time::HiRes::time() + 0.1, \&IRBlastSendCallback, (\$ircode));
}

# ---------------------------------------------------------------------------- 
sub IRBlastSendCallback {
	my $client = shift;
	my $ircoderef = shift;

	if( $client->isa( "Slim::Player::Squeezebox2")) {
		# Set GeekMode(Blaster)
		my $geekmode = pack( 'C', 1);
		$client->sendFrame( 'geek', \$geekmode);
	}
	
	$client->sendFrame( 'blst', $ircoderef);
}

# ----------------------------------------------------------------------------
sub IRBlastPulse {
	my $hightime = shift;
	my $lowtime = shift;
	my $MODULATION = shift;

	my $ircode = pack('n', int($hightime / $MODULATION));
	$ircode .= pack('n', int($lowtime / $MODULATION));
	
	return $ircode;
}

1;


