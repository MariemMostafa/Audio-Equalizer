close all;
clear;
clc;

%---Input---%

prompt = {'Filename:','Type of filters used (1.FIR  2.IIR):','Output sample rate:'};
equalizer = inputdlg(prompt,'EQUALIZER', 1);
if isempty(equalizer)
    return;
end
filename=equalizer{1};
type=str2double(equalizer{2});
Fs=str2double(equalizer{3});

if isempty(Fs)||isempty(filename)||isempty(type)||Fs<32000
    f = msgbox('Invalid Value', 'Error','error');
    Fs=0;
    filename=0;
    type=0;
    return;
end

prompt = {'0 - 170','170 - 310','310 - 600','600 - 1000','1k - 3k','3k - 6k','6k - 12k','12k - 14k','14k - 16k','16k - ∞'};
gains = inputdlg(prompt,'GAIN OF EACH BAND', 1);
if isempty(gains)
    return;
end
bandgains=[ str2double(gains{1}),str2double(gains{2}),str2double(gains{3}),str2double(gains{4}),str2double(gains{5}),str2double(gains{6}),str2double(gains{7}),str2double(gains{8}),str2double(gains{9}),str2double(gains{10})]; %arraybof inputgains 
bandwidth= [0 170 310 600 1000 3000 6000 12000 14000 16000]; 

%---Code---%

[y ,fs] = audioread(filename);    % Take input sound
fm=fs/2;            %modulating frequency of fs 
ynew=0;             %Variable for composite sound
n=length(y);        % Length of input sound
t=1:n;              % Time range of input signal

for i=1:10          % For loop on frequency ranges

if type==1          % Type 1- Use FIR filter
    if i==1         % Use lowpass FIR filter upto 170  
    [num,den] = fir1(50,bandwidth(i+1)/fm,'low');       % Filter sound signal by specified range
    
    elseif i>1&&i<10
    bandlow = bandwidth(i);                 % Get Low band
    bandhigh = bandwidth(i+1);              % Get High band
    wp = [bandlow/fm bandhigh/fm];          % Get band pass range
    [num,den] = fir1(50,wp,'bandpass');     % Filter sound signal by specified range
    
    else
    [num,den] = fir1(50,bandwidth(10)/fm,'high');       % Use high pass filter
    end

else        % IIR filter case 
    if i==1                                              % Use lowpass FIR filter upto 170
    [num,den] = butter(2,bandwidth(i+1)/fm,'low');       % Filter sound signal by specified range 
    
    elseif i>1&&i<10
    bandlow = bandwidth(i);                  % Get Low band
    bandhigh = bandwidth(i+1);               % Get High band
    wp = [bandlow/fm bandhigh/fm];           % Get band pass range
    [num,den] = butter(2,wp,'bandpass');     % Filter sound signal by specified range
    
    else
    [num,den] = butter(2,bandwidth(10)/fm,'high');       % Use high pass filter
    end

end

Bandgainspwr =  db2pow(bandgains(i));      % Convert gain from db to watt

y2 =  Bandgainspwr*filter(num,den,y);      % Amplification of signal using bandgains in watt

[H,w]=freqz(num,den,n);      %frequency response 
Hmag=abs(H);                 %magnitude response
Hphase=angle(H)*180/pi;      %phase response

figure;

%Figure 1
subplot(4,2,1);
plot(w,Hmag);grid on         %plot magnitude response
title('Magnitude');

%Figure 2
subplot(4,2,2);
plot(w,Hphase);grid on       %plot phase response
title('Phase')

%Figure 3
subplot(4,2,3);
impz(num,den);               %plot impulse response

%Figure 4
subplot(4,2,4);
stepz(num,den);              %plot step response

%Figure 5
subplot(4,2,5);
zplane(num,den);             %plot poles and zeros
title('Poles and Zeros');

%Figure 6
subplot(4,2,6);
plot(real(fftshift(fft(y2))));             %plot signal (frequency domain)
title('Signal (Frequency Domain)')

%Figure 7
subplot(4,2,7);
plot(t,y2);             %plot signal (time domain)
title('Signal (Time Domain)')

ynew=ynew + y2;     % Add filtered signal to composite sound

end

yresampled= resample(ynew,Fs,fs);     % Resample sound with output sample rate entered by user

sound(yresampled,Fs);      % Play composite sound

figure;              % Plot filtered signal

subplot(2,2,1);
plot(t,ynew);        % Plot filtered signal (time domain)
title('Filtered Signal (Time)');

outputfreq = fftshift(fft(ynew));
Fvec = linspace(-fm,fm,n);

subplot(2,2,2);
plot(real(outputfreq));             % Plot filtered signal (frequency domain)
title('Filtered Signal (Frequency)');

subplot(2,2,3);
plot(Fvec,abs(outputfreq));          % Plot filtered signal (magnitude)
title('Filtered Signal (Frequency-mag)');

subplot(2,2,4);
plot(Fvec,angle(outputfreq));        %plot filtered signal (phase)
title('Filtered Signal (Frequency-phase)');

figure;                              % Plot original signal

subplot(2,2,1);
plot(t,y);                           %plot original signal (time domain)
title('Original Signal (Time)');

originalfreq = fftshift(fft(y));
Fvec = linspace(-fm,fm,n);

subplot(2,2,2);
plot(real(originalfreq));            %plot original signal (frequency domain)
title('Original Signal (Frequency)');

subplot(2,2,3);
plot(Fvec,abs(originalfreq));        %plot original signal (magnitude)
title('Original Signal (Magnitude)');

subplot(2,2,4);
plot(Fvec,angle(originalfreq));       %plot filtered signal (phase)
title('Original Signal (Phase)');

%audiowrite('E:\Term 6\DSP\Assignment 4\FinalSound.wav',ynew,fs);
