CollisionData = load('OfflineTestingCollisionDataFrictionRaw.csv');
FreeData = load('OfflineTestingFreeDataFrictionRaw.csv');

Max20thResidual = load('ResiMax.csv');
Min20thResidual = -Max20thResidual;
%%
cd ../result
LSTMCollision = load('offline_testing_result_collision.csv');
LSTMFree = load('offline_testing_result_free.csv');

dt = 0.001;
last_t = 0.000;
threshold = load('Threshold.csv');

%% Collision
ResiCollision = CollisionData(:,86:91);
for i = 1:6
    LSTMCollision(:,i) = (Max20thResidual(i) - Min20thResidual(i)) * LSTMCollision(:,i)/2 + (Max20thResidual(i) + Min20thResidual(i))/2;
end
LSTMCollision = [ResiCollision(1,:); LSTMCollision];

collision_pre = 0;
collision_cnt = 0;
collision_time = 0;
detection_time_DOB = [];
collision_status = false;
DOB_detection = false;
collision_fail_cnt_DOB = 0;

t= last_t:dt:last_t+(size(LSTMCollision,1)-1)*dt;
last_t = last_t + size(LSTMCollision,1)*dt;

Switch_data = CollisionData(:,65);
DOB_Collision = ResiCollision(1:size(LSTMCollision,1),:) - LSTMCollision;

continueous_col = 0;
continueous_col_judge = 0;

for i=1:size(LSTMCollision,1)
    if (Switch_data(i) == 1 && collision_pre ==0)
        collision_cnt = collision_cnt +1;
        collision_time = i*dt;
        collision_status = true;
        DOB_detection = false;
    end
    
    if (collision_status == true && DOB_detection == false)
        if(abs(DOB_Collision(i,1))>threshold(1) || abs(DOB_Collision(i,2))>threshold(2) ||abs(DOB_Collision(i,3))>threshold(3) ||abs(DOB_Collision(i,4))>threshold(4) ||abs(DOB_Collision(i,5))>threshold(5) ||abs(DOB_Collision(i,6))>threshold(6))
            continueous_col = continueous_col+1;
            if continueous_col > continueous_col_judge
                continueous_col = 0;
                DOB_detection = true;
                detection_time_DOB(collision_cnt) = i*dt - collision_time;
            end
        end
    end
    
    if (Switch_data(i) == 0 && collision_pre ==1)
        collision_status = false;
        if(DOB_detection == false)
            detection_time_DOB(collision_cnt) = 0.0;
            collision_fail_cnt_DOB = collision_fail_cnt_DOB+1;
        end
    end
    
    collision_pre = Switch_data(i);
end

disp("Number of Collisions:")
disp(collision_cnt)
disp("Detection Delay DOB:")
disp(sum(detection_time_DOB)/(collision_cnt-collision_fail_cnt_DOB))
disp("Detection Failure DOB:")
disp(collision_fail_cnt_DOB)

f5 = figure;
for i =1:6
    subplot(2,3,i)
    plot(ResiCollision(:,i))
    hold on
    plot(LSTMCollision(:,i))
end
%% Free
DOB_FP = 0;
DOB_FP_time = [];
DOB_FP_joint = [];

ResiFree = FreeData(:,86:91);
for i = 1:6
    LSTMFree(:,i) = (Max20thResidual(i) - Min20thResidual(i)) * LSTMFree(:,i)/2 + (Max20thResidual(i) + Min20thResidual(i))/2;
end
LSTMFree = [ResiFree(1,:); LSTMFree];
DOB_Free = ResiFree(1:size(LSTMFree,1),:) - LSTMFree;

last_t = 0.000;
t= last_t:dt:last_t+(size(LSTMFree,1)-1)*dt;
last_t = last_t + size(LSTMFree,1)*dt;
Switch_data = FreeData(:,65);

continueous_col = 0;

for i=1:size(LSTMFree,1)
    if (Switch_data(i) == 0 && (abs(DOB_Free(i,1))>threshold(1) || abs(DOB_Free(i,2))>threshold(2) ||abs(DOB_Free(i,3))>threshold(3) ||abs(DOB_Free(i,4))>threshold(4) ||abs(DOB_Free(i,5))>threshold(5) ||abs(DOB_Free(i,6))>threshold(6)))
        continueous_col = continueous_col+1;
        if continueous_col > continueous_col_judge
            continueous_col = 0;
            DOB_FP = DOB_FP +1;
            DOB_FP_time(DOB_FP) = t(i);
            for joint = 1:6
                if abs(DOB_Free(i,joint))>threshold(joint)
                    DOB_FP_joint(DOB_FP) = joint;
                end
            end
        end
    end
end

    
disp("-----------------------------")
disp("FP DoB:")
disp(DOB_FP)
disp("-----------------------------")
disp("DOB FP Time:")
for i=2:DOB_FP
    del_time = abs(DOB_FP_time(i)-DOB_FP_time(i-1));
    if( del_time> 0.5)
        disp(del_time)
        fprintf('Joint %d\n',DOB_FP_joint(i));
    end
end

f6 = figure;
for i =1:6
    subplot(2,3,i)
    plot(ResiFree(:,i))
    hold on
    plot(LSTMFree(:,i))
end
