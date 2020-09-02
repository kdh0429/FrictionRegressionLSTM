clc
clear all

LSTMCollision1 = load('offline_testing_result_collision_1.csv');
LSTMFree1 = load('offline_testing_result_free_1.csv');
LSTMCollision2 = load('offline_testing_result_collision_2.csv');
LSTMFree2 = load('offline_testing_result_free_2.csv');
LSTMCollision3 = load('offline_testing_result_collision_3.csv');
LSTMFree3 = load('offline_testing_result_free_3.csv');
cd ../../data
CollisionData = load('OfflineTestingCollisionDataFrictionRaw.csv');
FreeData = load('OfflineTestingFreeDataFrictionRaw.csv');


dt = 0.001;
last_t = 0.000;
threshold1 = 0.45*[31.510573890686032  22.604903012084961  21.030845558166504   5.354460573005676   4.444364891242981   4.934903097915649];
threshold2 = 0.45*[18.695395507812499  21.956626678466797  11.850344573974610   7.111924628448486  12.361756106376648   5.433331510925293];
threshold3 = 0.45*[21.068768905639651  40.870186721801758  23.965332649230959   6.725629309844971  11.656245779991149  10.846590120315552];

%% Collision
ResiCollision = CollisionData(:,86:91);
LSTMCollision1 = [ResiCollision(1,:); LSTMCollision1];
LSTMCollision2 = [ResiCollision(1,:); LSTMCollision2];
LSTMCollision3 = [ResiCollision(1,:); LSTMCollision3];

collision_pre = 0;
collision_cnt = 0;
collision_time = 0;
detection_time_DOB = [];
collision_status = false;
DOB_detection = false;
collision_fail_cnt_DOB = 0;

t= last_t:dt:last_t+(size(LSTMCollision1,1)-1)*dt;
last_t = last_t + size(LSTMCollision1,1)*dt;

Switch_data = CollisionData(:,65);
DOB_Collision_1 = ResiCollision(1:size(LSTMCollision1,1),:) - LSTMCollision1;
DOB_Collision_2 = ResiCollision(1:size(LSTMCollision2,1),:) - LSTMCollision2;
DOB_Collision_3 = ResiCollision(1:size(LSTMCollision3,1),:) - LSTMCollision3;

continueous_col = 0;
continueous_col_judge = 0;

for i=1:size(LSTMCollision1,1)
    if (Switch_data(i) == 1 && collision_pre ==0)
        collision_cnt = collision_cnt +1;
        collision_time = i*dt;
        collision_status = true;
        DOB_detection = false;
    end
    
    if (collision_status == true && DOB_detection == false)
        if(abs(DOB_Collision_1(i,1))>threshold1(1) || abs(DOB_Collision_1(i,2))>threshold1(2) ||abs(DOB_Collision_1(i,3))>threshold1(3) ||abs(DOB_Collision_1(i,4))>threshold1(4) ||abs(DOB_Collision_1(i,5))>threshold1(5) ||abs(DOB_Collision_1(i,6))>threshold1(6)) && ...
          (abs(DOB_Collision_2(i,1))>threshold2(1) || abs(DOB_Collision_2(i,2))>threshold2(2) ||abs(DOB_Collision_2(i,3))>threshold2(3) ||abs(DOB_Collision_2(i,4))>threshold2(4) ||abs(DOB_Collision_2(i,5))>threshold2(5) ||abs(DOB_Collision_1(i,6))>threshold2(6)) && ...
          (abs(DOB_Collision_3(i,1))>threshold3(1) || abs(DOB_Collision_3(i,2))>threshold3(2) ||abs(DOB_Collision_3(i,3))>threshold3(3) ||abs(DOB_Collision_3(i,4))>threshold3(4) ||abs(DOB_Collision_3(i,5))>threshold3(5) ||abs(DOB_Collision_3(i,6))>threshold3(6))
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

f1 = figure;
for i =1:6
    subplot(2,3,i)
    plot(ResiCollision(:,i))
    hold on
    plot(LSTMCollision1(:,i))
    plot(LSTMCollision2(:,i))
    plot(LSTMCollision3(:,i))
end
%% Free
DOB_FP = 0;
DOB_FP_time = [];
DOB_FP_joint = [];

ResiFree = FreeData(:,86:91);
LSTMFree1 = [ResiFree(1,:); LSTMFree1];
DOB_Free_1 = ResiFree(1:size(LSTMFree1,1),:) - LSTMFree1;

LSTMFree2 = [ResiFree(1,:); LSTMFree2];
DOB_Free_2 = ResiFree(1:size(LSTMFree2,1),:) - LSTMFree2;

LSTMFree3 = [ResiFree(1,:); LSTMFree3];
DOB_Free_3 = ResiFree(1:size(LSTMFree3,1),:) - LSTMFree3;

last_t = 0.000;
t= last_t:dt:last_t+(size(LSTMFree1,1)-1)*dt;
last_t = last_t + size(LSTMFree1,1)*dt;
Switch_data = FreeData(:,65);

continueous_col = 0;

for i=1:size(LSTMFree1,1)
    if (Switch_data(i) == 0 && (abs(DOB_Free_1(i,1))>threshold1(1) || abs(DOB_Free_1(i,2))>threshold1(2) ||abs(DOB_Free_1(i,3))>threshold1(3) ||abs(DOB_Free_1(i,4))>threshold1(4) ||abs(DOB_Free_1(i,5))>threshold1(5) ||abs(DOB_Free_1(i,6))>threshold1(6)) && ...
        (abs(DOB_Free_2(i,1))>threshold2(1) || abs(DOB_Free_2(i,2))>threshold2(2) ||abs(DOB_Free_2(i,3))>threshold2(3) ||abs(DOB_Free_2(i,4))>threshold2(4) ||abs(DOB_Free_2(i,5))>threshold2(5) ||abs(DOB_Free_2(i,6))>threshold2(6)) && ...
        (abs(DOB_Free_3(i,1))>threshold3(1) || abs(DOB_Free_3(i,2))>threshold3(2) ||abs(DOB_Free_3(i,3))>threshold3(3) ||abs(DOB_Free_3(i,4))>threshold3(4) ||abs(DOB_Free_3(i,5))>threshold3(5) ||abs(DOB_Free_3(i,6))>threshold3(6)))
         continueous_col = continueous_col+1;
        if continueous_col > continueous_col_judge
            continueous_col = 0;
            DOB_FP = DOB_FP +1;
            DOB_FP_time(DOB_FP) = t(i);
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
    end
end

f2 = figure;
for i =1:6
    subplot(2,3,i)
    plot(ResiFree(:,i))
    hold on
    plot(LSTMFree1(:,i))
    plot(LSTMFree2(:,i))
    plot(LSTMFree3(:,i))
end