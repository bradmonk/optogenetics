function [outputSignal] = makepulse(s, pulseDuration, pulseIPI)
%% makepulse.m USAGE NOTES AND CREDITS
% 
% Syntax
% -----------------------------------------------------
%     nidaq(vrts,tets)
%     nidaq(vrts,tets,'filename.xml')
%     nidaq(____,'doctype','xmlns')
% 
% Description
% -----------------------------------------------------
%     nidaq() takes a set of 2D or 3D vertices (vrts) and a tetrahedral (tets)
%     connectivity list, and creates an XML file of the mesh. This function was 
%     originally created to export xml mesh files for using in Fenics:Dolfin 
%     but can be adapted for universal xml export of triangulated meshes.
%
%
% EXPAND FOR MORE...
%{
% Useage Definitions
% -----------------------------------------------------
% 
% 
%     xmlmesh(vrts,tets)
%         creates an XML file 'xmlmesh.xml' from a set of vertices "vrts"
%         and a connectivity list; here the connectivity list is referred 
%         to as "tets". These parameters can be generated manually, or by
%         using matlab's builtin triangulation functions. The point list
%         "vrts" is a matrix with dimensions Mx2 (for 2D) or Mx3 (for 3D).
%         The matrix "tets" represents the triangulated connectivity list 
%         of size Mx3 (for 2D) or Mx4 (for 3D), where M is the number of 
%         triangles. Each row of tets specifies a triangle defined by indices 
%         with respect to the points. The delaunayTriangulation function
%         can be used to quickly generate these input variables:
%             TR = delaunayTriangulation(XYZ);
%             vrts = TR.Points;
%             tets = TR.ConnectivityList;
% 
% 
%     xmlmesh(vrts,tets,'filename.xml')
%         same as above, but allows you to specify the xml filename.
% 
% 
%     xmlmesh(____,'doctype','xmlns')
%         same as above, but allows you to additionally specify the
%         xml namespace xmlns attribute. For details see:
%         http://www.w3schools.com/xml/xml_namespaces.asp
% 
% 
% 
% 
% Example
% -----------------------------------------------------
%
% Create 2D triangulated mesh
%     XY = randn(10,2);
%     TR2D = delaunayTriangulation(XY);
%     vrts = TR2D.Points;
%     tets = TR2D.ConnectivityList;
% 
%     xmlmesh(vrts,tets,'xmlmesh_2D.xml')
% 
% 
% Create 3D triangulated mesh
%     d = [-5 8];
%     [x,y,z] = meshgrid(d,d,d); % a cube
%     XYZ = [x(:) y(:) z(:)];
%     TR3D = delaunayTriangulation(XYZ);
%     vrts = TR3D.Points;
%     tets = TR3D.ConnectivityList;
% 
%     xmlmesh(vrts,tets,'xmlmesh_3D.xml')
% 
% 
% Attribution
% -----------------------------------------------------
% Created by: Bradley Monk
% email: brad.monk@gmail.com
% website: bradleymonk.com
% 2016.06.19
%
% 
% Potentially Helpful Resources and Documentation
% -----------------------------------------------------
% General brad code resources:
%     > http://bradleymonk.com/MATLAB
%     > https://github.com/subroutines
%
% Info related to this function/script:
%     > <a href="matlab: 
% web('http://www.mathworks.com/help/daq/ref/daq.getdevices.html')">daq.getdevices</a>
%     > <a href="matlab: 
% web(fullfile(docroot, 'instrument/examples.html'))">instrument control toolbox</a>
%
%   See also daqread, instrhwinfo

%}


% if nargin > 0
%     
%     % [nidaq.vendor, nidaq.device, etc] = deal(varargin{:});
%     nidaq = varargin;
%     
% else
%     
%     nidaq.vendor        = 'ni';
%     nidaq.device        = 'Dev2';
%     nidaq.channelOut    = 'ao0';
%     nidaq.channelIn     = 'ao1';
%     nidaq.outtype       = 'Voltage';
%     nidaq.rate          = 8000;
%     nidaq.volt          = 1000;
%     
% end

pulseDuration = 100; % ms
pulseIPI = 900; % ms



%% Queue an output then run output later

% Create and plot a single sine wave and step function
outputSignal1 = sin(linspace(0,pi*2,s.Rate)');
outputSignal2 = linspace(-1,1,s.Rate)';

pulseTiming = [ones(1,pulseDuration) zeros(1,pulseIPI)];

pulseNpossible = floor(s.Rate / numel(pulseTiming));

pulsePatternPerSec = repmat(pulseTiming,1,pulseNpossible);

pulsePatternPerSec(end:s.Rate) = 0;

outputSignal = pulsePatternPerSec;


figure(99)
plot(outputSignal1);
hold on;
plot(outputSignal2,'-g');
hold on;
plot(outputSignal,'-r');
xlabel('Time');
ylabel('Voltage');
% legend('Analog Output 0', 'Analog Output 1');






%{
% This will get info about all daq devices
devices = daq.getDevices;
devices(2)

% Open a session using national instruments drivers
s = daq.createSession('ni');

% Make ready the two output channels
addAnalogOutputChannel(s,'Dev2','ao0','Voltage')
addAnalogOutputChannel(s,'Dev2','ao1','Voltage')

% You can change the output rate like so...
s.Rate = 8000;

% Create a constant output value of 5 volts
outputSingleValue = 5;
outputSingleScan(s,[outputSingleValue outputSingleValue]);


% Bring output value back to 0 volts
outputSingleValue = 0;
outputSingleScan(s,[outputSingleValue outputSingleValue]);


%% Queue an output then run output later
clc; close all; clear;

% This will get info about all daq devices
devices = daq.getDevices;
devices(2)

% Open a session using national instruments drivers
s = daq.createSession('ni');

% Make ready the two output channels
addAnalogOutputChannel(s,'Dev2','ao0','Voltage')
addAnalogOutputChannel(s,'Dev2','ao1','Voltage')


stop(s)

% You can change the output rate like so...
s.Rate = 8000;

% Create and plot a single sine wave and step function
outputSignal1 = sin(linspace(0,pi*2,s.Rate)');
outputSignal2 = linspace(-1,1,s.Rate)';
outputSignal3 = sin(linspace(0, 2*pi*1000, 10001))';

plot(outputSignal3)
% plot(outputSignal1);
% hold on;
% plot(outputSignal2,'-g');
xlabel('Time');
ylabel('Voltage');
legend('Analog Output 0', 'Analog Output 1');

% Queue that signal for output
queueOutputData(s,[outputSignal3 outputSignal3]);

%% OUTPUT THE QUEUED SIGNAL TO THE DAQ

s.startForeground;

%}

end


























