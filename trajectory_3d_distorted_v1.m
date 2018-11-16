% Construct trajectory of table tennis ball from DISTORTED tracking data.
% This program uses mldivide to solve the linear system.

% statistics - camera 1
R(:,:,1) = [ 9.6428667991264605e-1 -2.6484969138677328e-1 -2.4165916859785336e-3;
      -8.9795446022112396e-2 -3.1832382771611223e-1 -9.4371961862719200e-1;
       2.4917459103354755e-1  9.1023325674273947e-1 -3.3073772313234923e-1];
t(:,:,1) = -R(:,:,1)\[1.3305621037591506e-1;
      -2.5319578738559911e-1;
       2.2444637695699150e0];
C(:,:,1) = [ 8.7014531487461625e2                   0   9.4942001822880479e2;
                        0    8.7014531487461625e2 4.8720049852775117e2; 
                        0                     0                    1   ];


% statistics - camera 2
R(:,:,2) = [ 9.4962278945631540e-1  3.1338395965783683e-1 -2.6554800661627576e-3; 
       1.1546856489995427e-1 -3.5774736713426591e-1 -9.2665194751235791e-1; 
      -2.9134784753821596e-1  8.7966318277945221e-1 -3.7591104878304971e-1];
t(:,:,2) = -R(:,:,2)\[-4.2633372670025989e-2; 
      -3.5441906393933242e-1;
       2.2750378317324982e0];
C(:,:,2) = [ 8.9334367240024267e2                   0   9.4996816131377727e2;
                        0    8.9334367240024267e2 5.4679562177577259e2;
                        0                     0                    1   ];


% statistics - camera 3
R(:,:,3) = [-9.9541881789113029e-1  3.8473906154401757e-2 -8.7527912881817604e-2;
       9.1201836523849486e-2  6.5687400820094410e-1 -7.4846426926387233e-1;
       2.8698466908561492e-2 -7.5301812454631367e-1 -6.5737363964632056e-1];
t(:,:,3) = -R(:,:,3)\[-6.0451734755080713e-2;
      -3.9533167111966377e-1;
       2.2979640654841407e0];                 
C(:,:,3) = [ 8.7290852997159800e2                   0   9.4445161471037636e2;
                        0    8.7290852997159800e2 5.6447334036925656e2;
                        0                     0                    1   ];
% loop through all annotations
% code taken from here - 
% https://www.mathworks.com/matlabcentral/answers/284135-how-to-open-the-files-in-a-directory
clips_num = 10;
% set x_offset = xcoord(center of measurement - center of image plane)
x_offset = -1920/2; % temporary set to 0 - awaiting prof for clarification
% set y_offset = ycoord(center of measurement - center of image plane)
y_offset = -1080/2; % temporary set to 0 - awaiting prof for clarification

for i = 1 : clips_num
    fprintf("Constructing 3D trajectory for scene %d\n",i);
    folder_name = strcat('Annotation/',num2str(i));
    folder_info = dir(fullfile(folder_name));
    folder_info([folder_info.isdir]) = []; % get rid of nesting folders
    nfiles = length(folder_info); % number of files in this annotation folder - should be 3
    % read csv into multidimensional array cam
    clear cam;
    for j = 1 : nfiles
        fname = fullfile(folder_name, folder_info(j).name);
        fprintf("Loading data for camera %d from file %s\n",j,fname);
        data = csvread(fname,2,1);
        cam(:,:,j) = data;
    end
    
    [m,n,p] = size(cam);
    
    % initialize output csv file to store the trajectory
    output_fname = strcat(folder_name,'/output3d.csv');
   
    % initialize vector to store the trajectory
    output = zeros(m,4);
    
    % keep track of number of "good" frames
    valid_frame_count = 0;
    
    for frm = 1 : m
        flag = 0;
        left_mat = zeros(6,3);
        right_mat = zeros(6,1);
        for cam_idx = 1 : 3
            u_fp = cam(frm,1,cam_idx);
            v_fp = cam(frm,2,cam_idx);

            if isnan(u_fp) || u_fp == 0
                flag = 1;
                break
            end
            if isnan(v_fp) || v_fp == 0
                flag = 1;
                break
            end
            
            bleft_u = (u_fp - C(1,3,cam_idx))*R(3,:,cam_idx) - C(1,1,cam_idx)*R(1,:,cam_idx);
            bleft_v = (v_fp - C(2,3,cam_idx))*R(3,:,cam_idx) - C(2,2,cam_idx)*R(2,:,cam_idx);
            left_mat(2*cam_idx-1,:) = bleft_u;
            left_mat(2*cam_idx,:) = bleft_v;
            right_mat(2*cam_idx-1,:) = (bleft_u)*t(:,:,cam_idx);
            right_mat(2*cam_idx,:) = (bleft_v)*t(:,:,cam_idx);
        end
        
        % skip if frame does not contain enough valid data
        if flag == 1
            continue
        end
        
        % solve linear system if frame contains enough data
        sol = mldivide(left_mat, right_mat);
        output(valid_frame_count + 1,:) = [valid_frame_count + 1 sol(1,1) sol(2,1) sol(3,1)];
        valid_frame_count = valid_frame_count + 1;
    end
    
    % plotting of trajectory
    X = output(1:valid_frame_count,2);
    Y = output(1:valid_frame_count,3);
    Z = output(1:valid_frame_count,4);
    
    windowSize = 6;
    smoothX = zeros(valid_frame_count - windowSize,1);
    smoothY = zeros(valid_frame_count - windowSize,1);
    smoothZ = zeros(valid_frame_count - windowSize,1);
    for valid_frame = windowSize + 1 : valid_frame_count
        smoothX(valid_frame - windowSize,1) = mean(X(valid_frame - windowSize : valid_frame,1));
        smoothY(valid_frame - windowSize,1) = mean(Y(valid_frame - windowSize : valid_frame,1));
        smoothZ(valid_frame - windowSize,1) = mean(Z(valid_frame - windowSize : valid_frame,1));
    end
    figure
    plot3(smoothX,smoothY,smoothZ,'o-')
    
    % write trajectory to output csv file
    % csvwrite(output_fname,output);
end