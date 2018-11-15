% statistics - camera 1
R = [ 9.6428667991264605e-1 -2.6484969138677328e-1 -2.4165916859785336e-3;
      -8.9795446022112396e-2 -3.1832382771611223e-1 -9.4371961862719200e-1;
       2.4917459103354755e-1  9.1023325674273947e-1 -3.3073772313234923e-1];
t = [ 1.3305621037591506e-1;
      -2.5319578738559911e-1;
       2.2444637695699150e0];
C = [ 8.7014531487461625e2                   0   9.4942001822880479e2;
                        0    8.7014531487461625e2 4.8720049852775117e2; 
                        0                     0                    1   ];


% statistics - camera 2
R(:,:,2) = [ 9.4962278945631540e-1  3.1338395965783683e-1 -2.6554800661627576e-3; 
       1.1546856489995427e-1 -3.5774736713426591e-1 -9.2665194751235791e-1; 
      -2.9134784753821596e-1  8.7966318277945221e-1 -3.7591104878304971e-1];
t(:,:,2) = [-4.2633372670025989e-2; 
      -3.5441906393933242e-1;
       2.2750378317324982e0];
C(:,:,2) = [ 8.9334367240024267e2                   0   9.4996816131377727e2;
                        0    8.9334367240024267e2 5.4679562177577259e2;
                        0                     0                    1   ];


% statistics - camera 3
R(:,:,3) = [-9.9541881789113029e-1  3.8473906154401757e-2 -8.7527912881817604e-2;
       9.1201836523849486e-2  6.5687400820094410e-1 -7.4846426926387233e-1;
       2.8698466908561492e-2 -7.5301812454631367e-1 -6.5737363964632056e-1];
t(:,:,3) = [-6.0451734755080713e-2;
      -3.9533167111966377e-1;
       2.2979640654841407e0];                 
C(:,:,3) = [ 8.7290852997159800e2                   0   9.4445161471037636e2;
                        0    8.7290852997159800e2 5.6447334036925656e2;
                        0                     0                    1   ];
% loop through all annotations
% code taken from here - 
% https://www.mathworks.com/matlabcentral/answers/284135-how-to-open-the-files-in-a-directory
for i = 1 : 11
    folder_name = strcat('Annotations/',num2str(i));
    folder_info = dir(fullfile(folder_name));
    folder_info([folder_info.isdir]) = []; % get rid of nesting folders
    nfiles = length(folder_info); % number of files in this annotation folder - should be 3
    % read csv into multidimensional array cam
    for j = 1 : nfiles
        fname = fullfile(folder_name, folder_info(j).name);
        if j == 1
            cam = csvread(fname);
        else
            cam(:,:,j) = csvread(fname);
        end
    end
    % read the csv(s) frame by frame
    [m,n,p] = size(cam);
    output_fname = strcat(folder_name,'/output3d.csv');
    output = zeros(m,4);
    for j = 1 : m
        left_mat = zeros(3,6);
        right_mat = zeros(1,6);
        for k = 1 : 3
            u_fp = cam(j,2,k);
            v_fp = cam(j,3,k);
            if u_fp == -1
                continue
            end
            if v_fp == -1
                continue
            end
            bleft_1 = u_fp*transpose(R(3,:,k));
            bleft_2 = v_fp*transpose(R(3,:,k));
            bright_1 = C(1,1,k)*transpose(R(1,:,k)) + C(1,3,k)*transpose(R(3,:,k));
            bright_2 = C(2,2,k)*transpose(R(2,:,k)) + C(2,3,k)*transpose(R(3,:,k));
            left_mat(:,2*k-1) = bleft_1 - bright_1;
            left_mat(:,2*k) = bleft_2 - bright_2;
            right_mat(1,2*k-1) = transpose(t(:,:,k))*left_mat(:,2*k-1);
            right_mat(1,2*k) = transpose(t(:,:,k))*left_mat(:,2*k);
        end
        % solve for 3d coordinates using svd
        %left_mat = transpose(left_mat);
        %[Ua, Sa, Va] = svd(left_mat);
        %sol = Va(:,3);
        %output(j,:) = [j; sol(1,1); sol(2,1); sol(3,1)];

        % update - solve for 3d coordinates using mldivide
        left_mat = transpose(left_mat);
        right_mat = transpose(right_mat);
        sol = mldivide(left_mat, right_mat);
        output(j,:) = [j; sol(1,1); sol(2,1); sol(3,1)];
    end
    % try plotting
    trans_output = transpose(output);
    X = trans_output(2,:);
    Y = trans_output(3,:);
    Z = trans_output(4,:);
    figure
    scatter3(X,Z,Y,'filled');
    %csvwrite(output_fname,output);
end