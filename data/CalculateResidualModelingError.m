clear all
clc
format long

Original_hz = 1000;
Reduced_hz = 100;
Reduced_interval = Original_hz / Reduced_hz;

cd ..
cd data
DoosanMSeries_RoboticsToolBox_Simulator_Modeling_Error;

%% For normalization

Tool_list = ["0_00kg", "2_01kg", "5_01kg"];
Free_Aggregate_Data = [];

%% Training Set

% 날짜별
FolderName = dir;
folder_idx = 1;
for time_step = 1:size(FolderName,1)
    if ((size(FolderName(time_step).name,2) > 5) && (strcmp(FolderName(time_step).name(1:6), 'robot1')))
        DataFolderList(folder_idx) = string(FolderName(time_step).name);
        folder_idx = folder_idx + 1;
    end
end

% 자유모션
for joint_data = 1:size(DataFolderList,2)
    cd (DataFolderList(joint_data))
    FolderName = dir;
    for k = 1:size(FolderName,1)
        if strcmp(FolderName(k).name, 'free')
            cd('free')
            %for tool_idx = 1:3
                cd 0_00kg %cd (Tool_list(tool_idx));
                NumFreeExpFolderName = dir;
                for collision_num =1:size(NumFreeExpFolderName,1)-2
                    cd (int2str(collision_num))
                    pwd
                    
                    ReducedDataFree = load('Reduced_DRCL_Data.txt');
                    AngleMFree = ReducedDataFree(:,8:13);
                    VelMFree = ReducedDataFree(:,14:19);
                    Motor_Torque = ReducedDataFree(:,2:7);
                    
                    ResidualEstimate_5 = zeros(size(ReducedDataFree,1),6);
                    ResidualEstimate_10 = zeros(size(ReducedDataFree,1),6);
                    ResidualEstimate_20 = zeros(size(ReducedDataFree,1),6);
                    K_5 = diag([5.0, 5.0, 5.0, 5.0, 5.0, 5.0]);
                    K_10 = diag([10.0, 10.0, 10.0, 10.0, 10.0, 10.0]);
                    K_20 = diag([20.0, 20.0, 20.0, 20.0, 20.0, 20.0]);
                    
                    integral_5 = zeros(1,6);
                    integral_10 = zeros(1,6);
                    integral_20 = zeros(1,6);
                    
                    for m = 2:size(ReducedDataFree,1)
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
                    
                    ReducedDataFree = [ReducedDataFree,ResidualEstimate_5,ResidualEstimate_10,ResidualEstimate_20];
                    save('Reduced_DRCL_Data_Resi_Modeling_Error_Inertia_50.txt', 'ReducedDataFree', '-ascii', '-double', '-tabs')
                    cd ..;
                end
                cd ..;
            %end
            cd ..;
        end
    end
    cd ..;
end