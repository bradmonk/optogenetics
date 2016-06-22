
%% CREATE SQUARE WAVE
clc; close all; clear;

pulse.number = 30;                  % (n) total number of pulses per session

pulse.duration = 100;                % (ms) duration of each pulse

pulse.ipi = 1000 - pulse.duration;  % (ms) inter pulse interval

pulses = [ones(1,pulse.duration) , zeros(1,pulse.ipi)];

pulses = repmat(pulses,1,pulse.number);



plot(pulses);
ylim([0 1.2])


%% ACQUIRE DAQ DEVICE

d = daq.getDevices;

s = daq.createSession('ni');

addAnalogInputChannel(s,'cDAQ1Mod1',0,'Voltage');
disp(s)

data = s.startForeground();

plot(data)

s.Rate = 5000;
s.DurationInSeconds = 2;
disp(s)


%%

% creates the VISA object obj with a resource name given by rsrcname 
% for the vendor specified by vendor...

obj = visa('vendor','rsrcname') 

% You must first configure your VISA resources in the vendor's tool first, 
% and then you create these VISA objects. Use instrhwinfo to find the 
% commands to configure the objects:

vinfo = instrhwinfo('visa','agilent');
vinfo.ObjectConstructorName

% EXAMPLES Create a VISA-serial object connected to serial port COM1 using
% National Instruments® VISA interface.

vs = visa('ni','ASRL1::INSTR');

% Create a VISA-GPIB object connected to board 0 with primary address 1 and
% secondary address 30 using Agilent Technologies® VISA interface.

vg = visa('agilent','GPIB0::1::30::INSTR');

%Create a VISA-VXI object connected to a VXI instrument located at logical
% address 8 in the first VXI chassis.

vv = visa('agilent','VXI0::8::INSTR');

% Create a VISA-GPIB-VXI object connected to a GPIB-VXI instrument located
% at logical address 72 in the second VXI chassis.

vgv = visa('agilent','GPIB-VXI1::72::INSTR');

% Create a VISA-RSIB object connected to an instrument configured with IP
% address 192.168.1.33.

vr = visa('ni', 'RSIB::192.168.1.33::INSTR')

% Create a VISA-TCPIP object connected to an instrument configured with IP
% address 216.148.60.170.

vt = visa('tek', 'TCPIP::216.148.60.170::INSTR')

% Create a VISA-USB object connected to a USB instrument with manufacturer
% ID 0x1234, model code 125, and serial number A22-5.

vu = visa('agilent', 'USB::0x1234::125::A22-5::INSTR')

