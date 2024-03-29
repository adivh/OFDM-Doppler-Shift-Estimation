% this file analyses the recorded signal, shows that the change of
% constellation of different symbols
clear all, close all, clc;

%% setting

Fs = 44100;   % sapmling frequency
N_sc = 512;  % number of carriers
bw_sc = Fs/N_sc;    %bandwidth of each subcarrier
ifft_size = 2*N_sc;
bidata_len = N_sc;  %binary data length

cp_length = 256;  % the pre and post fix are the same length of ifft_size, hereby I used both cyclic prefix and postfix
symbolCP_len = ifft_size + cp_length;    % symbol length with prefix and postfix
blank_len = 100;    % there is a blank interval between two frames
N_symbol = 100;     % number of symbol in a frame
N_frame = 2;        % number of frames in generated audio file
N_cluster = N_frame;
t = [1:symbolCP_len]'/Fs;
deg = zeros(N_symbol,1);    % angle of each symbol, unit degree

sc_mask = zeros(N_sc,1);   % subcarrier mask
sc_active = [100 200];    % active subcarrier index
sc_mask(sc_active) = 1;    % only active subcarriers are enabled to transmit data, others are blocked
sc_step = 100;

sync_offset = 0;

filename = '../res/mehmedali/unfiltered/512-fullspeed.wav'; %BH = better hardware
%% preamble
f_min = 8000;
f_max = 12000;
pre_len = 1024;
t_prehalf = [1:pre_len/2]/Fs;
t_lasthalf = [pre_len/2+1:pre_len]/Fs;
preamble = [chirp(t_prehalf,f_min,pre_len/2/Fs,f_max),...
    chirp(t_lasthalf,f_max,pre_len/Fs,f_min)]';

frame_len = pre_len + symbolCP_len * 10 + blank_len*2;

%% synchronization, find index using matched filter
[sig_received fs] = audioread(filename);
coef_MF_preamble = preamble(end:-1:1);
data_MFflted = filter(coef_MF_preamble,1,sig_received);

figure;
plot(data_MFflted);

sync_threshold = 0.2;

index_arr = find(data_MFflted > sync_threshold);
index_arr_sorted = sort_index(data_MFflted,index_arr,N_cluster);
disp(index_arr_sorted);


%% design of bandpass and lowpass FIR filter
% % lowpass filter
% Fp_LP = 4000/Fs;
% Fs_LP = 6000/Fs;
% order = 127;
% coef_LP = firls(order,[0 Fp_LP Fs_LP 1],[1 1 0 0]);
%bandpass filter 16kHz ~ 18.4kHz
Fs1_BP = 300*2/Fs;
Fp1_BP = 600*2/Fs;
Fp2_BP = 20750*2/Fs;
Fs2_BP = 21050*2/Fs;
order = 127;
coef_BP = firls(order,[0 Fs1_BP Fp1_BP Fp2_BP Fs2_BP 1],[0 0 1 1 0 0]);

%% demodulation

sc_active_backup = sc_active;

for i = 1:N_cluster
    sc_mask = zeros(N_sc,1);   % subcarrier mask
    sc_active = i*sc_step;    % active subcarrier index
    sc_mask(sc_active) = 1;
    
    hMod = comm.BPSKModulator;    % creating bpsk modulator system object
    hMod.PhaseOffset = pi/16;     % phase set to pi/16

    binary_data = ones(N_sc,1);
    BPSK_data = step(hMod,binary_data).*sc_mask;   % this is the bpsk modulated data
    for j = 1:N_symbol
        index_symbol = j;
        i_start = index_arr_sorted(i) + blank_len + symbolCP_len*(index_symbol-1) + 1 + sync_offset ;
        i_end = i_start + symbolCP_len - 1;
        target_sym = sig_received(i_start: i_end);
        
        symbol_woCP = target_sym(cp_length + 1 : end - cp_length);
        frequency_data = fft(symbol_woCP);
        BPSK_demodulated = frequency_data(1:N_sc);
        % normalization
        BPSK_demodulated = BPSK_demodulated / (max(abs(BPSK_demodulated)));
        
        q = sc_active_backup(2) + 1;
        deg(j) = angle(BPSK_demodulated(q));    % calculate the angle of a symbol
        
        if i == 90
            figure;
            xlim([-1 1]);
            ylim([-1 1]);
            hold on;
            plot(BPSK_data,'ro','MarkerSize',10,'linewidth',1.5);
            plot(BPSK_demodulated,'x','MarkerSize',10,'linewidth',1.5);
            for p = 1:N_sc
                if sc_mask(p)
                    x = real(BPSK_demodulated(p));
                    y = imag(BPSK_demodulated(p));
                    text(x,y,num2str(p-1));
                    x = real(BPSK_demodulated(p+1));
                    y = imag(BPSK_demodulated(p+1));
                    text(x,y,num2str(p));
                    x = real(BPSK_demodulated(p+2));
                    y = imag(BPSK_demodulated(p+2));
                    text(x,y,num2str(p+1));
                end
            end
            title (['EXP: N\_sc=',num2str(N_sc),', sc:#',num2str(sc_active),', symbol:',num2str(j)]);
        end
    end
    if i == 90
        close all;
    end
    
    % show accumulate phase rotation across all the symbols in one frame
    figure;
    plot(unwrap(deg)/pi);
    xlabel('symbol index');
    ylabel('accumulated phase rotation/pi');
    title(['N\_sc = ',num2str(N_sc),', Asc=',num2str(q-1)]);
    v_angular = gradient(unwrap(deg)/pi)';
end

disp("end");
