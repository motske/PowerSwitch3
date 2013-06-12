PowerSwitch III
===============

SqueezeServer (k/n/a Logitech Media Server) Plugin to control an amplifier's power state based on a power states of multiple devices

This project is based directly on Felix's PowerSwitch II:

http://www.gwendesign.com/slimserver/dev_hard_and_software.htm#powerswitchii

The intent is to be able to use the power state of one or more squeezebox clients (e.g., multiple instances of squeezeLite on a PogoPlug or Raspberry Pi) in conjunction with the ir/geek port of a SqueezeBox/Transporter to control a multi-zone amplifier's power state by sending a low-volt trigger to a relay (e.g., amp/preamp with sensitive enough trigger input, powerstrip such as Belkin PureAV pf60, or home made ala www.gwendesign.com).

Oh, yeah, as of 6/7/13 revisions, it now works!

Install instructions:
1.  Install files (download and unzip to /Plugins/PowerSwitchIII subfolder--information on location of /Plugins folder can be found at http://wiki.slimdevices.com/index.php/Logitech_Media_Server_Plugins; may need to make PowerSwitchIII subfolder; make sure no subdirectories created within /PowerSwitchIII when unzipping files);
2.  Restart SqueezeServer; 
3.  Activate Plugin (open SqueezeServer web interface, open settings (bottom right corner), select plugins tab and check PowerSwitch III);
4.  Apply changes; and
5.  Identify clients utilizing trigger (SqueezeBox2 & Transporter, turn on/off PowerSwitch III in "extra" menu; all others, just include a "~" in their name--e.g., LivingRm~)  
