clear all

cd ../../Offline_Experiment/20191122_Test/robot1/0_00kg
cd collision
CollisionData = load('DRCL_Data_Resi.txt');
cd ../free
FreeData = load('DRCL_Data_Resi.txt');
cd ../../../../../FrictionRegression/result
LSTMCollision = load('offline_testing_result_collision.csv');
LSTMFree = load('offline_testing_result_free.csv');

dt = 0.001;
last_t = 0.000;
threshold = [18.310443191528321  23.698891021728517  13.387418884277345   5.264186576843262   7.253582011413574   4.820243186187744];

%% Collision
ResiCollision = CollisionData(:,86:91);
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

for i=1:size(LSTMCollision,1)
    if (Switch_data(i) == 1 && collision_pre ==0)
        collision_cnt = collision_cnt +1;
        collision_time = i*dt;
        collision_status = true;
        DOB_detection = false;
    end
    
    if (collision_status == true && DOB_detection == false)
        if(abs(DOB_Collision(i,1))>threshold(1) || DOB_Collision(DOB_Free(i,2))>threshold(2) ||abs(DOB_Collision(i,3))>threshold(3) ||abs(DOB_Collision(i,4))>threshold(4) ||abs(DOB_Collision(i,5))>threshold(5) ||abs(DOB_Collision(i,6))>threshold(6))
            DOB_detection = true;
            detection_time_DOB(collision_cnt) = i*dt - collision_time;
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

%% Free
DOB_FP = 0;
DOB_FP_time = [];

ResiFree = FreeData(:,86:91);
LSTMFree = [ResiFree(1,:); LSTMFree];
DOB_Free = ResiFree(1:size(LSTMFree,1),:) - LSTMFree;

last_t = 0.000;
t= last_t:dt:last_t+(size(LSTMFree,1)-1)*dt;
last_t = last_t + size(LSTMFree,1)*dt;
Switch_data = FreeData(:,65);

for i=1:size(LSTMFree,1)
    if (Switch_data(i) == 0 && (abs(DOB_Free(i,1))>threshold(1) || abs(DOB_Free(i,2))>threshold(2) ||abs(DOB_Free(i,3))>threshold(3) ||abs(DOB_Free(i,4))>threshold(4) ||abs(DOB_Free(i,5))>threshold(5) ||abs(DOB_Free(i,6))>threshold(6)))
        DOB_FP = DOB_FP +1;
        DOB_FP_time(DOB_FP) = t(i);
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