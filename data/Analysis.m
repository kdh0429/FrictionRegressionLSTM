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

%% Plot
for j=1:6
    subplot(2,3,j)
    plot(Motor_Torque(:,j) - JTS(:,j))
    hold on
    plot(ResidualEstimate(:,j))
    plot(FrictionModelPoly(:,j))
    plot(FrictionModelLSTM(:,j))
    legend('GT','MOB','Poly','LSTM')
end
