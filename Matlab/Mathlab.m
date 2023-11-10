classdef Signal_App < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        UIFigure                     matlab.ui.Figure
        GridLayout                   matlab.ui.container.GridLayout
        LeftPanel                    matlab.ui.container.Panel
        MIDISwitch                   matlab.ui.control.ToggleSwitch
        MIDISwitchLabel              matlab.ui.control.Label
        NoteLabel                    matlab.ui.control.Label
        FrequencyLabel               matlab.ui.control.Label
        DetectedNote                 matlab.ui.control.Label
        DetectedFreq                 matlab.ui.control.Label
        WaveTypeSelectorButtonGroup  matlab.ui.container.ButtonGroup
        SquareButton                 matlab.ui.control.RadioButton
        SawtoothButton               matlab.ui.control.RadioButton
        SineButton                   matlab.ui.control.RadioButton
        ReleaseKnob                  matlab.ui.control.Knob
        ReleaseKnob_2Label           matlab.ui.control.Label
        SustainKnob                  matlab.ui.control.Knob
        SustainKnob_2Label           matlab.ui.control.Label
        DecayKnob                    matlab.ui.control.Knob
        DecayKnob_2Label             matlab.ui.control.Label
        AmpADSRSwitch                matlab.ui.control.Switch
        AmplitudeSwitchLabel         matlab.ui.control.Label
        AttackKnob                   matlab.ui.control.Knob
        AttackKnob_2Label            matlab.ui.control.Label
        FreqADSRSwitch               matlab.ui.control.Switch
        FrequencySwitchLabel         matlab.ui.control.Label
        SustainFreq                  matlab.ui.control.Knob
        SustainKnobLabel             matlab.ui.control.Label
        DecayFreq                    matlab.ui.control.Knob
        DecayKnobLabel               matlab.ui.control.Label
        ReleaseFreq                  matlab.ui.control.Knob
        ReleaseKnobLabel             matlab.ui.control.Label
        AttackFreq                   matlab.ui.control.Knob
        AttackKnobLabel              matlab.ui.control.Label
        RightPanel                   matlab.ui.container.Panel
        FreqLabel                    matlab.ui.control.Label
        UIAxesWave                   matlab.ui.control.UIAxes
        UIAxesAmp                    matlab.ui.control.UIAxes
        UIAxesFreq                   matlab.ui.control.UIAxes
    end

    % Properties that correspond to apps with auto-reflow
    properties (Access = private)
        onePanelWidth = 576;
    end

    
    properties (Access = public)
        t; % signal values
        KeysFig; % Figure to handle key press
        WaveType;
        VecADSR_Amp;
        VecADSR_Freq;
        Dur; % Signal length in sec
        Fs; % Samples Rate
        
 
        
    end

    methods (Access = public)

    function simplesynth(app)
    
    midiInput = mididevice('Output','loopMIDI OUT');
    osc = audioOscillator(app.WaveType, 'Amplitude', 0);

    while true
        msgs = midireceive(midiInput);
        for i = 1:numel(msgs)
            msg = msgs(i);
            if isNoteOn(app,msg)
                osc.Frequency = note2freq(app,msg.Note);
                osc.Amplitude = msg.Velocity/127;
            elseif isNoteOff(app,msg)
                if msg.Note == msg.Note
                    osc.Amplitude = 0;
                end
            end
        end
    end
    end
 

 
    function yes = isNoteOn(~,msg)
        yes = msg.Type == midimsgtype.NoteOn ...
        && msg.Velocity > 0;
    end

    function freq = note2freq(~,note)
        freqA = 440;
        noteA = 69;
        freq = freqA * 2.^((note-noteA)/12);
    end

    function note = Freq2Note(~, freq)
            A4 = 440;
            C0 = A4*2.^-4.75;
            name = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"];
            try
                h = round(12*log2(freq/C0));
                octave = floor(h / 12);
                n = mod(h,12) + 1;
                note = strcat(name(n),num2str(octave));
            catch
                
            end
                
        end  
    
        
        % handle Frequency ADSR changed
        function handle_ADSRFreqChanged(app)
            [ADSR] = initADSR(app,app.AttackFreq.Value,app.DecayFreq.Value,app.SustainFreq.Value,app.ReleaseFreq.Value);
            
            env = getADSR(app,ADSR(1),ADSR(2),ADSR(3),ADSR(4),app.Dur,app.Fs);
            
            plot(app.UIAxesFreq,app.t,env);
        end
        
        % handle Amplitude ADSR changed
        function handle_ADSRAmpChanged(app)
                  
            [ADSR] = initADSR(app,app.AttackKnob.Value,app.DecayKnob.Value,app.SustainKnob.Value,app.ReleaseKnob.Value);
            
            env = getADSR(app,ADSR(1),ADSR(2),ADSR(3),ADSR(4),app.Dur,app.Fs);
            
            plot(app.UIAxesAmp,app.t,env);
        
        end
        
        % Calculate output signal by Amplitude, Frequency, Shift using the current envelopes values
        function WaveOut = getSound(app,Amp,Freq)
                       
            switch app.WaveType
                case 'Sine'
                    if strcmp(app.FreqADSRSwitch.Value, 'On')
                        envFreq = getADSR(app,app.VecADSR_Freq(1),app.VecADSR_Freq(2),app.VecADSR_Freq(3),app.VecADSR_Freq(4),app.Dur,app.Fs);
                        WaveOut = Amp * sin(2 * pi * Freq * envFreq .* app.t); % fourier synthesis
                    else
                        WaveOut = Amp * sin(2 * pi * Freq * app.t ); % fourier synthesis
                    end
                case 'Sawtooth'
                    if strcmp(app.FreqADSRSwitch.Value, 'On')
                        envFreq = getADSR(app,app.VecADSR_Freq(1),app.VecADSR_Freq(2),app.VecADSR_Freq(3),app.VecADSR_Freq(4),app.Dur,app.Fs);
                        WaveOut = Amp * sawtooth(2 * pi * Freq * envFreq .* app.t); % fourier synthesis
                    else
                        WaveOut = Amp * sawtooth(2 * pi * Freq .* app.t ); % fourier synthesis
                    end
                case 'Square'
                    if strcmp(app.FreqADSRSwitch.Value, 'On')
                        envFreq = getADSR(app,app.VecADSR_Freq(1),app.VecADSR_Freq(2),app.VecADSR_Freq(3),app.VecADSR_Freq(4),app.Dur,app.Fs);
                        WaveOut = Amp * square(2 * pi * Freq * envFreq .* app.t ); % fourier synthesis
                    else
                        WaveOut = Amp * square(2 * pi * Freq .* app.t ); % fourier synthesis
                    end
            end
            
            if strcmp(app.AmpADSRSwitch.Value, 'On')
                AmpEnvelope = getADSR(app,app.VecADSR_Amp(1),app.VecADSR_Amp(2),app.VecADSR_Amp(3),app.VecADSR_Amp(4),app.Dur,app.Fs);
                WaveOut = AmpEnvelope .* WaveOut;
            end
            
        end
        % Get envelopes vector by values of Attack, Decay, Sustain, Release and the signal length
        function y = getADSR(~,A, D, S, R, Dur, Fs)
            
            N = Dur * Fs;
            t = [0:N-1]/Fs;
            
            y = interp1([0 (0.01+A) (0.12+D) Dur - (0.601 - S) - R-0.02 Dur], [0 1 0.4 0.4 0], t,'linear'); % !!
            
        end

        
        % Get Attack, Decay, Sustain and Release values in a vector by the current values selcted in the UI
        function [ADSR] = initADSR(~,Attack,Decay,Sustain,Release)
            Atk = Attack;
            Dcy = Decay;
            Sus = Sustain;
            Rel = Release;
            
            [ADSR] = [Atk Dcy Sus Rel];
        end

        function plotSound(app,y)
            plot(app.UIAxesWave,app.t,y);
        end

        function handle_KeyPushed(app,keyFreq)

            [app.VecADSR_Freq] = initADSR(app,app.AttackFreq.Value,app.DecayFreq.Value,app.SustainFreq.Value,app.ReleaseFreq.Value);
            [app.VecADSR_Amp] = initADSR(app,app.AttackKnob.Value,app.DecayKnob.Value,app.SustainKnob.Value,app.ReleaseKnob.Value);
            
            
            Amp = 1; % amplitudes
            Freq = keyFreq; % frequencies
            
            
            soundOut = getSound(app,Amp,Freq); %Get output signal
            detectedFreq = ZeroCrossing(soundOut,app.Fs);
            note = Freq2Note(app,detectedFreq);
            app.DetectedNote.Text = note;
            app.DetectedFreq.Text = num2str(detectedFreq);


            soundsc(soundOut,app.Fs);
            plotSound(app,soundOut);
            
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
           app.UIFigure.Position = [0 50 700 500];
            app.Fs = 8196;
            app.Dur = 1;
            N = app.Dur * app.Fs;
            app.t = [0:N-1]/app.Fs;
            app.WaveType = 'Sine';
            
            
          
            [ADSR] = initADSR(app,app.AttackFreq.Value,app.DecayFreq.Value,app.SustainFreq.Value,app.ReleaseFreq.Value);
            app.VecADSR_Freq = getADSR(app,ADSR(1),ADSR(2),ADSR(3),ADSR(4),app.Dur,app.Fs);
            
            plot(app.UIAxesAmp,app.t,app.VecADSR_Freq);
            
            [ADSR] = initADSR(app,app.AttackFreq.Value,app.DecayFreq.Value,app.SustainFreq.Value,app.ReleaseFreq.Value);
            app.VecADSR_Amp = getADSR(app,ADSR(1),ADSR(2),ADSR(3),ADSR(4),app.Dur,app.Fs);
            
            plot(app.UIAxesFreq,app.t,app.VecADSR_Amp);
        end

        % Value changed function: AttackFreq
        function AttackFreqValueChanged(app, event)
            handle_ADSRFreqChanged(app);
            
        end

        % Value changed function: DecayFreq
        function DecayFreqValueChanged(app, event)
            handle_ADSRFreqChanged(app);
            
        end

        % Value changed function: SustainFreq
        function SustainFreqValueChanged(app, event)
            handle_ADSRFreqChanged(app);
            
        end

        % Value changed function: ReleaseFreq
        function ReleaseFreqValueChanged(app, event)
            handle_ADSRFreqChanged(app);
            
        end

        % Value changed function: AttackKnob
        function AttackKnobValueChanged(app, event)
            handle_ADSRAmpChanged(app);
            
        end

        % Value changed function: DecayKnob
        function DecayKnobValueChanged(app, event)
            handle_ADSRAmpChanged(app);
            
        end

        % Value changed function: SustainKnob
        function SustainKnobValueChanged(app, event)
           handle_ADSRAmpChanged(app);
            
        end

        % Value changed function: ReleaseKnob
        function ReleaseKnobValueChanged(app, event)
            handle_ADSRAmpChanged(app)
            
        end

        % Selection changed function: WaveTypeSelectorButtonGroup
        function WaveTypeSelectorButtonGroupSelectionChanged(app, event)

            selectedButton = app.WaveTypeSelectorButtonGroup.SelectedObject;
            app.WaveType = selectedButton.Text;
        end

        % Changes arrangement of the app based on UIFigure width
        function updateAppLayout(app, event)
            currentFigureWidth = app.UIFigure.Position(3);
            if(currentFigureWidth <= app.onePanelWidth)
                % Change to a 2x1 grid
                app.GridLayout.RowHeight = {475, 475};
                app.GridLayout.ColumnWidth = {'1x'};
                app.RightPanel.Layout.Row = 2;
                app.RightPanel.Layout.Column = 1;
            else
                % Change to a 1x2 grid
                app.GridLayout.RowHeight = {'1x'};
                app.GridLayout.ColumnWidth = {252, '1x'};
                app.RightPanel.Layout.Row = 1;
                app.RightPanel.Layout.Column = 2;
            end
        end

        % Value changed function: MIDISwitch
        function MIDISwitchValueChanged(app, event)
            value = app.MIDISwitch.Value;
            app.KeysFig = figure('KeyPressFcn', @KeyFcn, 'Name', 'Key Press' , 'Position',[-40,-40,0,0]); % new traditional figure with interactive features
            
            if strcmp(value , 'Off') 
                close all;
                          
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create UIFigure and hide until all components are created
            app.UIFigure = uifigure('Visible', 'off');
            app.UIFigure.AutoResizeChildren = 'off';
            app.UIFigure.Color = [0.149 0.149 0.149];
            app.UIFigure.Position = [100 100 731 475];
            app.UIFigure.Name = 'MATLAB App';
            app.UIFigure.Resize = 'off';
            app.UIFigure.SizeChangedFcn = createCallbackFcn(app, @updateAppLayout, true);
            app.UIFigure.WindowStyle = 'modal';

            % Create GridLayout
            app.GridLayout = uigridlayout(app.UIFigure);
            app.GridLayout.ColumnWidth = {252, '1x'};
            app.GridLayout.RowHeight = {'1x'};
            app.GridLayout.ColumnSpacing = 0;
            app.GridLayout.RowSpacing = 0;
            app.GridLayout.Padding = [0 0 0 0];
            app.GridLayout.Scrollable = 'on';

            % Create LeftPanel
            app.LeftPanel = uipanel(app.GridLayout);
            app.LeftPanel.Layout.Row = 1;
            app.LeftPanel.Layout.Column = 1;

            % Create AttackKnobLabel
            app.AttackKnobLabel = uilabel(app.LeftPanel);
            app.AttackKnobLabel.HorizontalAlignment = 'center';
            app.AttackKnobLabel.FontName = 'Bahnschrift';
            app.AttackKnobLabel.FontSize = 10;
            app.AttackKnobLabel.Position = [16 400 34 22];
            app.AttackKnobLabel.Text = 'Attack';

            % Create AttackFreq
            app.AttackFreq = uiknob(app.LeftPanel, 'continuous');
            app.AttackFreq.Limits = [0 0.1];
            app.AttackFreq.MajorTicks = [0 0.02 0.04 0.06 0.08 0.1];
            app.AttackFreq.MajorTickLabels = {'0', '', '', '', '', '10'};
            app.AttackFreq.ValueChangedFcn = createCallbackFcn(app, @AttackFreqValueChanged, true);
            app.AttackFreq.FontName = 'Bahnschrift';
            app.AttackFreq.FontSize = 10;
            app.AttackFreq.Position = [14 364 37 37];

            % Create ReleaseKnobLabel
            app.ReleaseKnobLabel = uilabel(app.LeftPanel);
            app.ReleaseKnobLabel.HorizontalAlignment = 'center';
            app.ReleaseKnobLabel.FontName = 'Bahnschrift';
            app.ReleaseKnobLabel.FontSize = 10;
            app.ReleaseKnobLabel.Position = [192 394 43 22];
            app.ReleaseKnobLabel.Text = 'Release';

            % Create ReleaseFreq
            app.ReleaseFreq = uiknob(app.LeftPanel, 'continuous');
            app.ReleaseFreq.Limits = [0 0.1];
            app.ReleaseFreq.MajorTicks = [0 0.02 0.04 0.06 0.08 0.1 0.12 0.15];
            app.ReleaseFreq.MajorTickLabels = {'0', '', '', '', '', '15'};
            app.ReleaseFreq.ValueChangedFcn = createCallbackFcn(app, @ReleaseFreqValueChanged, true);
            app.ReleaseFreq.FontName = 'Bahnschrift';
            app.ReleaseFreq.FontSize = 10;
            app.ReleaseFreq.Position = [196 362 33 33];

            % Create DecayKnobLabel
            app.DecayKnobLabel = uilabel(app.LeftPanel);
            app.DecayKnobLabel.HorizontalAlignment = 'center';
            app.DecayKnobLabel.FontName = 'Bahnschrift';
            app.DecayKnobLabel.FontSize = 10;
            app.DecayKnobLabel.Position = [77 400 32 22];
            app.DecayKnobLabel.Text = 'Decay';

            % Create DecayFreq
            app.DecayFreq = uiknob(app.LeftPanel, 'continuous');
            app.DecayFreq.Limits = [0 0.15];
            app.DecayFreq.MajorTicks = [0 0.02 0.04 0.06 0.08 0.1 0.12 0.15];
            app.DecayFreq.MajorTickLabels = {'0', '', '', '', '', '', '', '15'};
            app.DecayFreq.ValueChangedFcn = createCallbackFcn(app, @DecayFreqValueChanged, true);
            app.DecayFreq.FontName = 'Bahnschrift';
            app.DecayFreq.FontSize = 10;
            app.DecayFreq.Position = [74 364 37 37];

            % Create SustainKnobLabel
            app.SustainKnobLabel = uilabel(app.LeftPanel);
            app.SustainKnobLabel.HorizontalAlignment = 'center';
            app.SustainKnobLabel.FontName = 'Bahnschrift';
            app.SustainKnobLabel.FontSize = 10;
            app.SustainKnobLabel.Position = [137 398 39 22];
            app.SustainKnobLabel.Text = 'Sustain';

            % Create SustainFreq
            app.SustainFreq = uiknob(app.LeftPanel, 'continuous');
            app.SustainFreq.Limits = [0 0.6];
            app.SustainFreq.MajorTicks = [0 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6];
            app.SustainFreq.MajorTickLabels = {'0', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '60'};
            app.SustainFreq.ValueChangedFcn = createCallbackFcn(app, @SustainFreqValueChanged, true);
            app.SustainFreq.FontName = 'Bahnschrift';
            app.SustainFreq.FontSize = 10;
            app.SustainFreq.Position = [137 362 37 37];
            app.SustainFreq.Value = 0.3;

            % Create FrequencySwitchLabel
            app.FrequencySwitchLabel = uilabel(app.LeftPanel);
            app.FrequencySwitchLabel.HorizontalAlignment = 'center';
            app.FrequencySwitchLabel.FontName = 'Bookman';
            app.FrequencySwitchLabel.Position = [80 427 62 22];
            app.FrequencySwitchLabel.Text = 'Frequency';

            % Create FreqADSRSwitch
            app.FreqADSRSwitch = uiswitch(app.LeftPanel, 'slider');
            app.FreqADSRSwitch.Position = [102 453 22 10];

            % Create AttackKnob_2Label
            app.AttackKnob_2Label = uilabel(app.LeftPanel);
            app.AttackKnob_2Label.HorizontalAlignment = 'center';
            app.AttackKnob_2Label.FontName = 'Bahnschrift';
            app.AttackKnob_2Label.FontSize = 10;
            app.AttackKnob_2Label.Position = [16 255 34 22];
            app.AttackKnob_2Label.Text = 'Attack';

            % Create AttackKnob
            app.AttackKnob = uiknob(app.LeftPanel, 'continuous');
            app.AttackKnob.Limits = [0 0.1];
            app.AttackKnob.MajorTicks = [0 0.02 0.04 0.06 0.08 0.1];
            app.AttackKnob.MajorTickLabels = {'0', '', '', '', '', '10'};
            app.AttackKnob.ValueChangedFcn = createCallbackFcn(app, @AttackKnobValueChanged, true);
            app.AttackKnob.FontName = 'Bahnschrift';
            app.AttackKnob.FontSize = 10;
            app.AttackKnob.Position = [14 219 37 37];

            % Create AmplitudeSwitchLabel
            app.AmplitudeSwitchLabel = uilabel(app.LeftPanel);
            app.AmplitudeSwitchLabel.HorizontalAlignment = 'center';
            app.AmplitudeSwitchLabel.FontName = 'Bookman';
            app.AmplitudeSwitchLabel.Position = [85 287 58 22];
            app.AmplitudeSwitchLabel.Text = 'Amplitude';

            % Create AmpADSRSwitch
            app.AmpADSRSwitch = uiswitch(app.LeftPanel, 'slider');
            app.AmpADSRSwitch.Position = [105 313 22 10];
            app.AmpADSRSwitch.Value = 'On';

            % Create DecayKnob_2Label
            app.DecayKnob_2Label = uilabel(app.LeftPanel);
            app.DecayKnob_2Label.HorizontalAlignment = 'center';
            app.DecayKnob_2Label.FontName = 'Bahnschrift';
            app.DecayKnob_2Label.FontSize = 10;
            app.DecayKnob_2Label.Position = [79 253 32 22];
            app.DecayKnob_2Label.Text = 'Decay';

            % Create DecayKnob
            app.DecayKnob = uiknob(app.LeftPanel, 'continuous');
            app.DecayKnob.Limits = [0 0.15];
            app.DecayKnob.MajorTicks = [0 0.02 0.04 0.06 0.08 0.1 0.12 0.15];
            app.DecayKnob.MajorTickLabels = {'0', '', '', '', '', '', '', '15'};
            app.DecayKnob.ValueChangedFcn = createCallbackFcn(app, @DecayKnobValueChanged, true);
            app.DecayKnob.FontName = 'Bahnschrift';
            app.DecayKnob.FontSize = 10;
            app.DecayKnob.Position = [76 217 37 37];

            % Create SustainKnob_2Label
            app.SustainKnob_2Label = uilabel(app.LeftPanel);
            app.SustainKnob_2Label.HorizontalAlignment = 'center';
            app.SustainKnob_2Label.FontName = 'Bahnschrift';
            app.SustainKnob_2Label.FontSize = 10;
            app.SustainKnob_2Label.Position = [140 251 39 22];
            app.SustainKnob_2Label.Text = 'Sustain';

            % Create SustainKnob
            app.SustainKnob = uiknob(app.LeftPanel, 'continuous');
            app.SustainKnob.Limits = [0 0.6];
            app.SustainKnob.MajorTicks = [0 0.02 0.04 0.06 0.08 0.1 0.12 0.14 0.16 0.18 0.2 0.22 0.24 0.26 0.28 0.3 0.32 0.34 0.36 0.38 0.4 0.42 0.44 0.46 0.48 0.5 0.52 0.54 0.56 0.58 0.6];
            app.SustainKnob.MajorTickLabels = {'0', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '', '60'};
            app.SustainKnob.ValueChangedFcn = createCallbackFcn(app, @SustainKnobValueChanged, true);
            app.SustainKnob.FontName = 'Bahnschrift';
            app.SustainKnob.FontSize = 10;
            app.SustainKnob.Position = [140 215 37 37];
            app.SustainKnob.Value = 0.3;

            % Create ReleaseKnob_2Label
            app.ReleaseKnob_2Label = uilabel(app.LeftPanel);
            app.ReleaseKnob_2Label.HorizontalAlignment = 'center';
            app.ReleaseKnob_2Label.FontName = 'Bahnschrift';
            app.ReleaseKnob_2Label.FontSize = 10;
            app.ReleaseKnob_2Label.Position = [194 245 44 22];
            app.ReleaseKnob_2Label.Text = 'Release';

            % Create ReleaseKnob
            app.ReleaseKnob = uiknob(app.LeftPanel, 'continuous');
            app.ReleaseKnob.Limits = [0 0.1];
            app.ReleaseKnob.MajorTicks = [0 0.02 0.04 0.06 0.08 0.1 0.12 0.15];
            app.ReleaseKnob.MajorTickLabels = {'0', '', '', '', '', '15'};
            app.ReleaseKnob.ValueChangedFcn = createCallbackFcn(app, @ReleaseKnobValueChanged, true);
            app.ReleaseKnob.FontName = 'Bahnschrift';
            app.ReleaseKnob.FontSize = 10;
            app.ReleaseKnob.Position = [200 218 31 31];

            % Create WaveTypeSelectorButtonGroup
            app.WaveTypeSelectorButtonGroup = uibuttongroup(app.LeftPanel);
            app.WaveTypeSelectorButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @WaveTypeSelectorButtonGroupSelectionChanged, true);
            app.WaveTypeSelectorButtonGroup.BorderColor = [0.502 0.502 0.502];
            app.WaveTypeSelectorButtonGroup.ForegroundColor = [0.149 0.149 0.149];
            app.WaveTypeSelectorButtonGroup.TitlePosition = 'centertop';
            app.WaveTypeSelectorButtonGroup.Title = 'Wave Type Selector';
            app.WaveTypeSelectorButtonGroup.BackgroundColor = [0.9412 0.9412 0.9412];
            app.WaveTypeSelectorButtonGroup.FontName = 'Franklin Gothic Medium';
            app.WaveTypeSelectorButtonGroup.Position = [26 88 133 94];

            % Create SineButton
            app.SineButton = uiradiobutton(app.WaveTypeSelectorButtonGroup);
            app.SineButton.Text = 'Sine';
            app.SineButton.Position = [11 48 50 22];
            app.SineButton.Value = true;

            % Create SawtoothButton
            app.SawtoothButton = uiradiobutton(app.WaveTypeSelectorButtonGroup);
            app.SawtoothButton.Text = 'Sawtooth';
            app.SawtoothButton.Position = [11 26 73 22];

            % Create SquareButton
            app.SquareButton = uiradiobutton(app.WaveTypeSelectorButtonGroup);
            app.SquareButton.Text = 'Square';
            app.SquareButton.Position = [11 4 65 22];

            % Create DetectedFreq
            app.DetectedFreq = uilabel(app.LeftPanel);
            app.DetectedFreq.BackgroundColor = [0.8 0.8 0.8];
            app.DetectedFreq.HorizontalAlignment = 'center';
            app.DetectedFreq.FontName = 'Felix Titling';
            app.DetectedFreq.FontSize = 18;
            app.DetectedFreq.FontWeight = 'bold';
            app.DetectedFreq.Position = [111 10 103 50];
            app.DetectedFreq.Text = '';

            % Create DetectedNote
            app.DetectedNote = uilabel(app.LeftPanel);
            app.DetectedNote.BackgroundColor = [0.8 0.8 0.8];
            app.DetectedNote.HorizontalAlignment = 'center';
            app.DetectedNote.FontName = 'Felix Titling';
            app.DetectedNote.FontSize = 18;
            app.DetectedNote.FontWeight = 'bold';
            app.DetectedNote.Position = [34 11 52 50];
            app.DetectedNote.Text = '';

            % Create FrequencyLabel
            app.FrequencyLabel = uilabel(app.LeftPanel);
            app.FrequencyLabel.FontSize = 14;
            app.FrequencyLabel.Position = [127 60 71 22];
            app.FrequencyLabel.Text = 'Frequency';

            % Create NoteLabel
            app.NoteLabel = uilabel(app.LeftPanel);
            app.NoteLabel.FontName = 'Mongolian Baiti';
            app.NoteLabel.FontSize = 18;
            app.NoteLabel.Position = [40 58 40 24];
            app.NoteLabel.Text = 'Note';

            % Create MIDISwitchLabel
            app.MIDISwitchLabel = uilabel(app.LeftPanel);
            app.MIDISwitchLabel.HorizontalAlignment = 'center';
            app.MIDISwitchLabel.Position = [190 81 30 22];
            app.MIDISwitchLabel.Text = 'MIDI';

            % Create MIDISwitch
            app.MIDISwitch = uiswitch(app.LeftPanel, 'toggle');
            app.MIDISwitch.ValueChangedFcn = createCallbackFcn(app, @MIDISwitchValueChanged, true);
            app.MIDISwitch.Position = [200 139 10 24];

            % Create RightPanel
            app.RightPanel = uipanel(app.GridLayout);
            app.RightPanel.Layout.Row = 1;
            app.RightPanel.Layout.Column = 2;

            % Create UIAxesFreq
            app.UIAxesFreq = uiaxes(app.RightPanel);
            title(app.UIAxesFreq, 'Frequency Envelope')
            app.UIAxesFreq.FontName = 'Microsoft YaHei UI Light';
            app.UIAxesFreq.XLim = [0 1];
            app.UIAxesFreq.YLim = [0 1.2];
            app.UIAxesFreq.XTickLabel = '';
            app.UIAxesFreq.YTickLabel = '';
            app.UIAxesFreq.Color = [0.6863 0.6824 0.902];
            app.UIAxesFreq.GridColor = [0.149 0.149 0.149];
            app.UIAxesFreq.Box = 'on';
            app.UIAxesFreq.YGrid = 'on';
            app.UIAxesFreq.FontSize = 14;
            app.UIAxesFreq.Position = [18 334 414 94];

            % Create UIAxesAmp
            app.UIAxesAmp = uiaxes(app.RightPanel);
            title(app.UIAxesAmp, 'Amplitude Envelope')
            app.UIAxesAmp.FontName = 'Microsoft JhengHei UI Light';
            app.UIAxesAmp.XLim = [0 1];
            app.UIAxesAmp.YLim = [0 1.2];
            app.UIAxesAmp.XTickLabel = '';
            app.UIAxesAmp.YTickLabel = '';
            app.UIAxesAmp.Color = [0.6863 0.6824 0.902];
            app.UIAxesAmp.GridColor = [0.149 0.149 0.149];
            app.UIAxesAmp.Box = 'on';
            app.UIAxesAmp.YGrid = 'on';
            app.UIAxesAmp.FontSize = 14;
            app.UIAxesAmp.Position = [18 196 403 105];

            % Create UIAxesWave
            app.UIAxesWave = uiaxes(app.RightPanel);
            title(app.UIAxesWave, 'Output Sound')
            app.UIAxesWave.FontName = 'Microsoft YaHei UI Light';
            app.UIAxesWave.YLim = [-1 1];
            app.UIAxesWave.XTickLabelRotation = 0;
            app.UIAxesWave.XTickLabel = '';
            app.UIAxesWave.YTick = [-1 -0.5 0 0.5 1];
            app.UIAxesWave.YTickLabelRotation = 0;
            app.UIAxesWave.YTickLabel = '';
            app.UIAxesWave.ZTickLabelRotation = 0;
            app.UIAxesWave.Color = [0.702 0.7608 0.749];
            app.UIAxesWave.Box = 'on';
            app.UIAxesWave.YGrid = 'on';
            app.UIAxesWave.FontSize = 14;
            app.UIAxesWave.Position = [17 20 433 162];

            % Create FreqLabel
            app.FreqLabel = uilabel(app.RightPanel);
            app.FreqLabel.Enable = 'off';
            app.FreqLabel.Position = [449 452 25 22];
            app.FreqLabel.Text = '';

            % Show the figure after all components are created
            app.UIFigure.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = Signal_App

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.UIFigure)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.UIFigure)
        end
    end
end