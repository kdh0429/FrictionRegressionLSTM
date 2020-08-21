clc
clear all;
format long

%% Doosan Model
TestingRaw = load('TestingDataRaw.csv');
FrictionModelDoosan = TestingRaw(:,50:55);

%% Ground Truth
Motor_Torque = TestingRaw(:,2:7);
JTS = TestingRaw(:,68:73);
VelMFree = TestingRaw(:,14:19);

%% MOB
ResidualEstimate = TestingRaw(:,86:91);

%% Evaluation with Frction Model
TrainingRaw = load('TrainingDataRaw.csv');
Motor_TorqueTraining = TrainingRaw(:,2:7);
VelMFreeTraining = TrainingRaw(:,14:19);
ResidualEstimateTraining = TrainingRaw(:,86:91);
x = abs(VelMFreeTraining);
y=abs(ResidualEstimateTraining);
p = zeros(4,6);
for j=1:6
    p(:,j) = polyfit(x(:,j),y(:,j),3);
end

FrictionModelPoly = zeros(size(VelMFree));
for j=1:6
    FrictionModelPoly(:,j) = sign(VelMFree(:,j)).*polyval(p(:,j),abs(VelMFree(:,j)));
end

%% LSTM
cd ..
cd result
FrictionModelLSTM = load('testing_result.csv');

%% Plot Trajectory
f1 = figure;
for j=1:6
    subplot(2,3,j)
    plot(Motor_Torque(:,j) - JTS(:,j))
    hold on
    plot(ResidualEstimate(:,j))
    plot(FrictionModelPoly(:,j))
    plot(FrictionModelLSTM(:,j))
    legend('GT','MOB','Poly','LSTM')
end

%% Plot qdot
f2 = figure;
qdot = [0:0.001:2.1]';

for i=1:6
fm(:,i) = polyval(p(:,i),qdot);
end

for j= 1:6
    subplot(2,3,j)
    plot(abs(VelMFree(1:size(FrictionModelLSTM,1),j)), abs(ResidualEstimate(1:size(FrictionModelLSTM,1),j)))
    hold on
    plot(abs(VelMFree(1:size(FrictionModelLSTM,1),j)), abs(FrictionModelLSTM(:,j)))
    plot(qdot,fm(:,j))
    legend('MOB','LSTM','Poly')
end
