PowerSwitch III
===============

SqueezeServer (k/n/a Logitech Media Server) Plugin to control an amplifier's power state based on a power states of multiple devices

This project is based directly on Felix's PowerSwitch II:

http://www.gwendesign.com/slimserver/dev_hard_and_software.htm#powerswitchii

The intent is to be able to use the power state of one or more squeezebox clients (e.g., multiple instances of squeezeLite on a PogoPlug or Raspberry Pi) in conjunction with the ir/geek port of a SqueezeBox/Transporter to control a multi-zone amplifier's power state by sending a low-volt trigger to a relay (e.g., amp/preamp with sensitive enough trigger input, powerstrip such as Belkin PureAV pf60, or home made ala www.gwendesign.com).

Oh, yeah, as of v0.1 revisions, it now works!

Install instructions:
---------------------

1.  Install files (download and unzip to Squeezebox/server/Plugins/PowerSwitchIII directory--make sure no subdirectories created within PowerSwitchIII when unzipping);
2.  Restart SqueezeServer; 
3.  Activate Plugin (open SqueezeServer web interface, open settings (bottom right corner), select plugins tab and check PowerSwitch III);
4.  Apply changes; and
5.  Identify clients utilizing trigger (SqueezeBox2 & Transporter, turn on/off PowerSwitch III in "extra" menu; all others, just include a "~" in their name--e.g., LivingRm~) 

Known Issues
-------------

If you have more than one Squeezebox or Transporter on your network, there could be some strange behavior with your switch.  We are working on an update to address this.

Project Plan
------------
 
 1.  Fix issues caused if there are multiple switch capable devices on the network
 2.  Look at adding web settings instead of relying on name matching to identify greedy clients and IR capable clients.
