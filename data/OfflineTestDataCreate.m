clear all
clc
format long

%% Note that offline test is 1000hz
Original_hz = 1000;
Reduced_hz = 1000;
Reduced_interval = Original_hz / Reduced_hz;

%% For normalization
Data_type_list = ["collision", "free"];
Tool_list = ["0_00kg", "2_01kg", "5_01kg"];
Free_Aggregate_Data = [];

process_hz = 100;
num_data_type = 3; % ee_acc, k_m*i_m-torque_dyna, qdot
num_input = 6*num_data_type;
num_output = 6;
num_time_step = 20;

MaxTrainingData = ...
[1084.29400000000, ...
 120.060000000000,250.020000000000,115.350000000000,23.2064000000000,26.5216000000000,15.5008000000000, ... % 전류기반 토크 
 3.14098465900000,1.22155077600000,1.56935367400000,1.74515730300000,1.74443907700000,2.09445796900000, ... % 엔코더 각도
 2.10822396600000,2.09336168400000,2.09999140900000,2.11034161300000,2.10024253000000,2.10095300500000, ... % 엔코더 각속도
 3.14097105900000,1.22150102600000,1.56931818300000,1.74513059400000,1.74435841500000,2.09427755900000, ... % 목표 각도
 2.09384377700000,2.08323318700000,2.08988735900000,2.08986018600000,2.08862086600000,2.09270263100000, ... % 목표 각속도
 34.9191147892000,162.954713519584,67.3684504470000,13.9810390655040,13.6320709287200,2.29075547030726, ... % 동적 토크
 3.14051407300000,1.22378111000000,1.56902266200000,1.74646109500000,1.74485520900000,2.09647236800000, ... % 절대엔코더 각도
 2.37287653100000,2.22906583200000,2.22906583200000,2.34890808100000,2.32493963200000,2.37287650000007, ... % 절대엔코더 각속도
 48.2430303900000,67.8849790200000,34.2571894000000,13.9728846900000,14.6445557600000,12.8039640300000, ... % 추정 마찰력
 56.2967187500000,57.1990625000000,55.3943750000000,54.2342187500000,53.9764062500000,53.2029687500000, ... % 온도
 19.7972257177333,20.1979596250809,10.5354988120940, ... % 말단 가속도 
 0,1,1, ... % 스위치, JTS충돌, 전류충돌
 88.4050094000000,165.817021200000,71.7832347000000,14.0865250900000,21.2248692300000,4.23752877900000]; % JTS기반 토크 

MinTrainingData = ...
[0, ... % 시간 
-75.0600000000000,-234.720000000000,-108.300000000000,-26.4768000000000,-25.3344000000000,-15.5008000000000, ... % 전류기반 토크 
-3.14098465900000,-1.22155077600000,-1.56935367400000,-1.74515730300000,-1.74443907700000,-2.09445796900000, ... % 엔코더 각도 
-2.10822396600000,-2.09336168400000,-2.09999140900000,-2.11034161300000,-2.10024253000000,-2.10095300500000, ... % 엔코더 각속도
-3.13776299100000,-1.22147945000000,-1.57055937900000,-1.74494092400000,-1.74513995700000,-2.09412678200000, ... % 목표 각도
-2.09297770800000,-2.00518303100000,-2.08250773800000,-2.09206368700000,-2.08361237700000,-2.09256922000000, ... % 목표 각속도
-37.3276679915200,-162.457141878560,-68.2669754086000,-12.5635610481280,-14.1346787184800,-2.08469780631839, ... % 동적 토크
-3.14051407300000,-1.22378111000000,-1.56902266200000,-1.74646109500000,-1.74485520900000,-2.09647236800000, ... % 절대엔코더 각도
-2.37287653100000,-2.22906583200000,-2.22906583200000,-2.34890808100000,-2.32493963200000,-2.37287650000007, ... % 절대엔코더 각속도
-47.9859685900000,-61.6178723100000,-35.7297740200000,-15.0662095000000,-13.3583373700000,-12.8466518500000, ... % 추정 마찰력
35.027187499999997,34.382656249999997,35.671718749999997,37.218593749999997,36.574062499999997,34.640468749999997, ... % 온도
-23.0191386928541,-21.7926650199891,-14.9436694473599, ... % 말단 가속도
0,0,0, ... % 스위치, JTS충돌, 전류충돌
-34.2609202000000,-164.684405900000,-71.7884777000000,-13.8809822600000,-14.1790053100000,-3.28459505000000]; % JTS기반 토크

Max20thDeltaTau = 1.0e+02 *[0.905006330138240   1.399467057308960   0.722155408653000   0.184627169068800   0.167978174935200   0.145462126065450];
Min20thDeltaTau = [-54.574230250239971, -81.755785525519997, -48.424922904000027, -18.357145836999997, -16.868785960839997, -15.098161645126400];
Max20thQError = [0.012423192000000   0.010965226000000   0.011863092200000   0.011930928690000   0.011992674600000   0.012042461900000];
Min20thQError = [-0.012298105000000  -0.010928819520000  -0.011940370700000  -0.011913867300000  -0.012024721700000  -0.012147427300000];
Max20thQdotError = [ 0.031172751000000   0.028223563000000   0.039852978000000   0.037853069000000   0.039282329000000   0.029608574000000];
Min20thQdotError = [-0.031008746000000  -0.029433469920000  -0.037408829000000  -0.038431840000000  -0.037999309000000  -0.029778584000000];
MaxResidual = load('ResiMax.csv');
MinResidual = -MaxResidual;
Max20thEncoderError = [0.002700000000000   0.002100000000000   0.002200000000000   0.003100000000000   0.001120000000000   0.002300000000000];
Min20thEncoderError = [-0.001300000000000  -0.002870000000000  -0.002480000000000  -0.003400000000000  -0.001300000000000  -0.002400000000000];
MaxQddot = [3.648090000000089   3.039999999999998   4.350000000000009   3.688000000000002   3.299999999999993   3.420000000000001];;
MinQddot = -MaxQddot;
MaxQdotSquare = [4.327232040000000   3.095168158300030   3.891616310800066   4.051802643100034   4.135158853900035   4.184516181700033];
MinQdotSquare = [0 0 0 0 0 0];
MaxQdotCorri = [2.38364678670000,3.02673541730000,3.05212055850003,3.22641124680001,3.45352286560001,2.37626733470002,2.31548362110006,2.32087150650001,2.11782928740000,2.65391096070031,2.80763030570001,2.71676604820002,2.93371156410001,3.02865071520005,3.19050346410002];
MinQdotCorri = -MaxQdotCorri;
%% Free Motion
cd ..
cd ..
cd Offline_Experiment/20191122_Test/robot1/0_00kg

FreeProcessDataIdx = 1;
for data_idx = 1:2
    cd (Data_type_list(data_idx))
    pwd
    
    Data_Aggregate = load('DRCL_Data_Resi_Modeling_Error_COM_50.txt');
    RawData= zeros(size(Data_Aggregate));
    % Data Process
    TestProcessData= zeros(size(Data_Aggregate,1), num_input*num_time_step+num_output); % Log Torque sensor and DOB result also
    TestProcessDataIdx = 1;
    recent_wrong_dt_idx = 0;
    
    for k=Reduced_hz/process_hz*num_time_step:size(Data_Aggregate,1)
        % Check time stamp
        dt_data = round(Data_Aggregate(k,1) - Data_Aggregate(k-2*Reduced_hz/process_hz,1),3);
        if dt_data ~= 2/process_hz
            recent_wrong_dt_idx = k;
        end
        
        if k < recent_wrong_dt_idx + num_time_step
            continue
        end
        
        if norm(Data_Aggregate(k,26:31)) == 0
            continue
        end
        
        % Output
        for joint_data = 1:6
            TestProcessData(TestProcessDataIdx,num_input*num_time_step+joint_data) = 2*(Data_Aggregate(k,85+joint_data) - MinResidual(joint_data))/(MaxResidual(joint_data) - MinResidual(joint_data)) -1;
        end

        % Input
        for time_step=1:num_time_step
            corri_idx = 1;
            for joint_data=1:6
                TestProcessData(TestProcessDataIdx,num_input*(num_time_step-time_step)+joint_data) = 2*(Data_Aggregate(k-Reduced_hz/process_hz*(time_step-1),13+joint_data) - MinTrainingData(1,13+joint_data)) / (MaxTrainingData(1,13+joint_data) - MinTrainingData(1,13+joint_data)) -1; % theta dot
                %TestProcessData(TestProcessDataIdx,num_input*(num_time_step-time_step)+6+joint_data) = 2*((Data_Aggregate(k-Reduced_hz/process_hz*(time_step-1),7+joint_data) - Data_Aggregate(k-Reduced_hz/process_hz*(time_step-1),37+joint_data)) - Min20thEncoderError(1,joint_data)) / (Max20thEncoderError(1,joint_data) - Min20thEncoderError(1,joint_data)) -1; % qdot
                TestProcessData(TestProcessDataIdx,num_input*(num_time_step-time_step)+6+joint_data) = 2*(Data_Aggregate(k-Reduced_hz/process_hz*(time_step-1),7+joint_data) - MinTrainingData(1,7+joint_data)) / (MaxTrainingData(1,7+joint_data) - MinTrainingData(1,7+joint_data)) -1; % theta
                %TestProcessData(TestProcessDataIdx,num_input*(num_time_step-time_step)+6+joint_data) = 2*(Data_Aggregate(k-Reduced_hz/process_hz*(time_step-1),1+joint_data) - MinTrainingData(1,1+joint_data)) / (MaxTrainingData(1,1+joint_data) - MinTrainingData(1,1+joint_data)) -1; % motor torque
                TestProcessData(TestProcessDataIdx,num_input*(num_time_step-time_step)+12+joint_data) = 2*((Data_Aggregate(k-Reduced_hz/process_hz*(time_step-1),13+joint_data) - Data_Aggregate(k-Reduced_hz/process_hz*(time_step),13+joint_data))*process_hz - MinQddot(1,joint_data)) / (MaxQddot(1,joint_data) - MinQddot(1,joint_data)) -1; % theta ddot
                %TestProcessData(TestProcessDataIdx,num_input*(num_time_step-time_step)+12+joint_data) = 2*(Data_Aggregate(k-Reduced_hz/process_hz*(time_step),13+joint_data) - MinTrainingData(1,13+joint_data)) / (MaxTrainingData(1,13+joint_data) - MinTrainingData(1,13+joint_data)) -1; % theta dot pre
%                 TestProcessData(TestProcessDataIdx,num_input*(num_time_step-time_step)+18+joint_data) = (Data_Aggregate(k-Reduced_hz/process_hz*(time_step-1),13+joint_data)^2 - MinQdotSquare(1,joint_data)) / (MaxQdotSquare(1,joint_data) - MinQdotSquare(1,joint_data)); % theta
%                 for other_joint=joint_data+1:6
%                     TestProcessData(TestProcessDataIdx,num_input*(num_time_step-time_step)+24+corri_idx) = 2*(Data_Aggregate(k-Reduced_hz/process_hz*(time_step-1),13+joint_data)*Data_Aggregate(k-Reduced_hz/process_hz*(time_step-1),13+other_joint) - MinQdotCorri(1,corri_idx)) / (MaxQdotCorri(1,corri_idx) - MinQdotCorri(1,corri_idx))-1;
%                     corri_idx = corri_idx+1;
%                 end
            end
        end
        
        RawData(TestProcessDataIdx,:) = Data_Aggregate(k,:);
        TestProcessDataIdx = TestProcessDataIdx +1;
    end
    TestProcessDataIdx = TestProcessDataIdx-1;
    
    cd ../../../../../FrictionRegression/data
    if Data_type_list(data_idx)=="free"
        csvwrite('OfflineTestingFreeDataFriction.csv', TestProcessData(1:TestProcessDataIdx,:));
        csvwrite('OfflineTestingFreeDataFrictionRaw.csv', RawData(1:TestProcessDataIdx,:));
    end
    if Data_type_list(data_idx)=="collision"
        csvwrite('OfflineTestingCollisionDataFriction.csv', TestProcessData(1:TestProcessDataIdx,:));
        csvwrite('OfflineTestingCollisionDataFrictionRaw.csv', RawData(1:TestProcessDataIdx,:));
    end
    
    cd ../../Offline_Experiment/20191122_Test/robot1/0_00kg
end