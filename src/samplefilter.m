% clc
% 
% Fs = 44100;
% filepath_1 = '../res/adrian/';
% filepath_2 = '512-halfspeed.wav';
% 
% source = [filepath_1, 'unfiltered/', filepath_2];
% destination = [filepath_1, 'filtered/preamble/', filepath_2];
% 
% x = audioread(source);
% t = linspace(1, length(x) / Fs, length(x));
% db = linspace(-Fs/2,Fs/2,length(x));
% 
% figure;
% subplot(4, 1, 1)
% plot(t, x)
% 
% y = fft(x);
% 
% subplot(4, 1, 2)
% plot(db, fftshift(10 * log10(abs(y))))
% axis([-2.5e4 2.5e4 -50 50])
%     
% filter_preamble_start = [1; 15000 * length(y) / Fs];
% filter_preamble_stop = [5000 * length(y) / Fs; length(y) / 2];
% 
% filter_512_start = [];
% filter_512_stop = [];
% 
% for i = 1 : length(filter_preamble_start)
%     y(filter_preamble_start(i):filter_preamble_stop(i)) = 0;
%     y(length(y) - filter_preamble_stop(i) + 1:length(y) - filter_preamble_start(i) + 1) = 0;
% end
% 
% subplot(4, 1, 3)
% plot(db, fftshift(10 * log10(abs(y))))
% axis([-2.5e4 2.5e4 -50 50])
% 
% z = ifft(y);
% 
% subplot(4, 1, 4)
% plot(t, z)
% 
% %audiowrite(destination, z, Fs)

function f = filter_preamble(samples)

    Fs = 44100;
    filter_preamble_start = [1; floor(15000 * length(samples) / Fs)];
    filter_preamble_stop = [floor(5000 * length(samples) / Fs); length(samples) / 2];
    
    y = fft(samples);

    for i = 1 : length(filter_preamble_start)
        y(filter_preamble_start(i):filter_preamble_stop(i)) = 0;
        y(length(y) - filter_preamble_stop(i) + 1:length(y) - filter_preamble_start(i) + 1) = 0;
    end
    
    z = ifft(y)
    
    f = z;
end