clear all;
n = 16;
fprintf('\nPlease select a soundscape:\n');
fprintf('\n1.White Noise\n')
fprintf('\n2.Pink Noise\n')
fprintf('\n3.Rainstorm\n')
fprintf('\n4.Stream\n')
%Sound selection menu
while 1
    select = input('');
    if select == 1
        [noise, fs] = audioread('white_noise.wav');
        break;
    elseif select == 2
        [noise, fs] = audioread('pink_noise.wav');
        break;     
    elseif select == 3
        [noise, fs] = audioread('rain.wav');
        break;
    elseif select == 4
        [noise, fs] = audioread('stream.wav');
        break;   
    else
        fprintf('\nError: Invalid input. Please try again\n')       
    end
end
%Volume and time initialization
volume = input('Enter desired volume (0-100%):    ');
vol_adj = volume;
noise_output = noise.*(volume./100);
time = input('Enter desired time in seconds (0-30s):    ');
time_s = round(time.*fs);
noise_output = noise_output(1:time_s);
noise_output_ref = noise_output;

fprintf('\nPlease select a noise profiler:\n')
fprintf('\n1.Auto\n')
fprintf('\n2.Manual\n')
fprintf('\n3.No profiler\n')
%Profiler menu
while 1
    select = input('');
    if select == 1
        %Noise profile capture
        hRec = audiorecorder(44100,16,1);
        fprintf('\nWelcome to auto profiler\n');
        fprintf('\nThe program will now capture 3 seconds of background noise to better optimize your experience\n');
        fprintf('\nPress any key to begin capture. Please remain quiet for best results\n');
        pause;
        recordblocking(hRec,3);
        disp('Finished noise capture');
        disp('Generating noise profile...');
        capture = getaudiodata(hRec);
        capture = capture.*2;
        capture = bandpass(capture,[50 20000],44100);
        %Find peak frequency and magnitude of noise floor
        fs_floor = 44100;
        T_floor = 1/fs_floor;
        L_floor = length(capture);
        ft_floor = fft(capture);
        P2_floor = abs(ft_floor/L_floor);
        P1_floor = P2_floor(1:L_floor/2+1);
        P1_floor(2:end-1) = 2*P1_floor(2:end-1);
        [mag_floor,fmax_floor] = max(P1_floor);
        fmax_floor = (fmax_floor-1)/3;
        %Find peak frequency and magnitude of masker
        fs_mask = fs;
        T_mask = 1/fs_mask;
        L_mask = length(noise_output);
        ft_mask = fft(noise_output);
        P2_mask = abs(ft_mask/L_mask);
        P1_mask = P2_mask(1:L_mask/2+1);
        P1_mask(2:end-1) = 2*P1_mask(2:end-1);
        mag_mask = P1_mask(fmax_floor*3+1);
        %Scale masker band
        scale_factor = mag_floor/mag_mask;
        band_lower = bandpass(noise_output,[20 fmax_floor*0.8], fs);
        band_upper = bandpass(noise_output,[fmax_floor*1.2 20000], fs);
        band_mask = bandpass(noise_output,[fmax_floor*0.8 fmax_floor*1.2], fs);
        window_mask = band_upper + band_lower;
        noise_output_ref = band_mask.*scale_factor + window_mask;
        %Normalizing output and reapplying volume adjustment
        noise_output_ref = noise_output_ref./max(abs(noise_output_ref));
        noise_output = noise_output_ref.*(vol_adj./100);
        break;
    elseif select == 2
        prompt = {'20-200Hz(0-100%):','200Hz-500Hz(0-100%):','500-3000Hz(0-100%):','3000-20000Hz(0-100%):'};
        dlgtitle = 'Equalizer';
        dims = [1 35];
        definput = {'100','100','100','100'};
        disp('Applying equalization...')
        eq_level = inputdlg(prompt,dlgtitle,dims,definput);
        eq_level = str2double(eq_level);
        eq_level = eq_level./100;
        
        band1 = bandpass(noise_output,[20 200], fs);
        band2 = bandpass(noise_output,[200 500], fs);
        band3 = bandpass(noise_output,[500 3000], fs);
        band4 = bandpass(noise_output,[3000 20000], fs);
        noise_output = band1.*eq_level(1)+band2.*eq_level(2)+band3.*eq_level(3)+band4.*eq_level(4);
        break;     
    elseif select == 3
        break;  
    else
        fprintf('\nError: Invalid input. Please try again\n')       
    end
end
%Load audio data into player
player = audioplayer(noise_output,fs,n);

fprintf('\n\nPress any key to start playback...\n\n');
pause;
play(player);

txt = sprintf('\n\nLossless playback started @ %.0fHz %0.fbit\n',fs,n);
fprintf(txt);
    
playtime = length(noise)/fs;
    
txt = sprintf('\nTrack length: %0.f seconds\n\n',playtime);
fprintf(txt);

fprintf('\nType "vol" to adjust volume\n');
fprintf('\nType "eq" to adjust equalization\n');
fprintf('\nType "quit" to stop playblack and quit program\n');
%Main playback menu
while 1
    x = input('', 's');
    if strcmp(x, 'quit')
        stop(player);
        fprintf('Playback stopped. Quitting program...\n');
        break;
    elseif strcmp(x, 'vol')
        vol_adj = input('Enter desired volume (0-100%):    ');
        
        pause(player);
        current_sample = player.CurrentSample();
        noise_output = noise_output_ref(current_sample:end);
        noise_output = noise_output.*(vol_adj./100);
        player = audioplayer(noise_output,fs,n);
        play(player);
    elseif strcmp(x, 'eq')
        prompt = {'20-200Hz(0-100%):','200Hz-500Hz(0-100%):','500-3000Hz(0-100%):','3000-20000Hz(0-100%):'};
        dlgtitle = 'Equalizer';
        dims = [1 35];
        definput = {'100','100','100','100'};
        eq_level = inputdlg(prompt,dlgtitle,dims,definput);
        eq_level = str2double(eq_level);
        eq_level = eq_level./100;
        disp('Applying equalization...')
        
        pause(player);
        current_sample = player.CurrentSample();
        noise_output = noise(current_sample:end);
        noise_output = noise_output.*(vol_adj./100);
        band1 = bandpass(noise_output,[20 200], fs);
        band2 = bandpass(noise_output,[200 500], fs);
        band3 = bandpass(noise_output,[500 3000], fs);
        band4 = bandpass(noise_output,[3000 20000], fs);
        noise_output = band1.*eq_level(1)+band2.*eq_level(2)+band3.*eq_level(3)+band4.*eq_level(4);
        
        player = audioplayer(noise_output,fs,n);
        play(player);
    else
        fprintf('\nError: Invalid input. Please try again\n')
    end
end