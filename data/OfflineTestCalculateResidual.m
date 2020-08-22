clear all
clc
format long

Original_hz = 1000;
Reduced_hz = 1000;
Reduced_interval = Original_hz / Reduced_hz;

cd ..
cd ..
cd data
DoosanMSeries_RoboticsToolBox_Simulator;

%% For normalization
Data_type_list = ["collision", "free"];
Tool_list = ["0_00kg", "2_01kg", "5_01kg"];
Free_Aggregate_Data = [];

%% Training Set

cd ..
cd Offline_Experiment/20191122_Test/robot1/0_00kg

for data_idx = 1:2
    cd (Data_type_list(data_idx))
    data_file = dir('DRCL_Data.*');
    Data_Aggregate = [];
    for file_idx = size(data_file,1)-1:-1:0
        if file_idx == 0
            Data = load('DRCL_Data.txt');
        else
            file_name = strcat('DRCL_Data.txt','.',int2str(file_idx));
            Data = load(file_name);
        end
        Data_Aggregate = [Data_Aggregate; Data];
    end
    
    AngleMFree = Data_Aggregate(:,8:13);
    VelMFree = Data_Aggregate(:,14:19);
    Motor_Torque = Data_Aggregate(:,2:7);
    
    ResidualEstimate_5 = zeros(size(Data_Aggregate,1),6);
    ResidualEstimate_10 = zeros(size(Data_Aggregate,1),6);
    ResidualEstimate_20 = zeros(size(Data_Aggregate,1),6);
    K_5 = diag([5.0, 5.0, 5.0, 5.0, 5.0, 5.0]);
    K_10 = diag([10.0, 10.0, 10.0, 10.0, 10.0, 10.0]);
    K_20 = diag([20.0, 20.0, 20.0, 20.0, 20.0, 20.0]);
    
    integral_5 = zeros(1,6);
    integral_10 = zeros(1,6);
    integral_20 = zeros(1,6);
    
    for m = 2:size(Data_Aggregate,1)
        Coriolis_T_Vel = -(bot.coriolis(AngleMFree(m,:),VelMFree(m,:))*VelMFree(m,:)');
        Gravity_Torque = -(bot.gravload(AngleMFree(m,:)))';
        Inertia = bot.inertia(AngleMFree(m,:));
        
        integral_5 = (integral_5' + (Motor_Torque(m,:)'+Coriolis_T_Vel - Gravity_Torque - ResidualEstimate_5(m-1,:)')/Reduced_hz)';
        ResidualEstimate_5(m,:) = (K_5*(integral_5' - Inertia*VelMFree(m,:)'))';
        integral_10 = (integral_10' + (Motor_Torque(m,:)'+Coriolis_T_Vel - Gravity_Torque - ResidualEstimate_10(m-1,:)')/Reduced_hz)';
        ResidualEstimate_10(m,:) = (K_10*(integral_10' - Inertia*VelMFree(m,:)'))';
        integral_20 = (integral_20' + (Motor_Torque(m,:)'+Coriolis_T_Vel - Gravity_Torque - ResidualEstimate_20(m-1,:)')/Reduced_hz)';
        ResidualEstimate_20(m,:) = (K_20*(integral_20' - Inertia*VelMFree(m,:)'))';
        
        if mod(m,2000) == 0
            m
        end
    end
    
    Data_Aggregate = [Data_Aggregate,ResidualEstimate_5,ResidualEstimate_10,ResidualEstimate_20];
    save('DRCL_Data_Resi.txt', 'Data_Aggregate', '-ascii', '-double', '-tabs')
    cd ..;
end