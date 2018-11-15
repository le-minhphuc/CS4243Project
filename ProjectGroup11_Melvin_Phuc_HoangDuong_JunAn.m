R1 = [ 9.6428667991264605e-1 -2.6484969138677328e-1 -2.4165916859785336e-3;
      -8.9795446022112396e-2 -3.1832382771611223e-1 -9.4371961862719200e-1;
       2.4917459103354755e-1  9.1023325674273947e-1 -3.3073772313234923e-1];
t1 = [ 1.3305621037591506e-1;
      -2.5319578738559911e-1;
       2.2444637695699150e0];
C1 = [ 8.7014531487461625e2                   0   9.4942001822880479e2;
                        0    8.7014531487461625e2 4.8720049852775117e2; 
                        0                     0                    1   ];



R2 = [ 9.4962278945631540e-1  3.1338395965783683e-1 -2.6554800661627576e-3; 
       1.1546856489995427e-1 -3.5774736713426591e-1 -9.2665194751235791e-1; 
      -2.9134784753821596e-1  8.7966318277945221e-1 -3.7591104878304971e-1];
t2 = [-4.2633372670025989e-2; 
      -3.5441906393933242e-1;
       2.2750378317324982e0];
C2 = [ 8.9334367240024267e2                   0   9.4996816131377727e2;
                        0    8.9334367240024267e2 5.4679562177577259e2;
                        0                     0                    1   ];



R3 = [-9.9541881789113029e-1  3.8473906154401757e-2 -8.7527912881817604e-2;
       9.1201836523849486e-2  6.5687400820094410e-1 -7.4846426926387233e-1;
       2.8698466908561492e-2 -7.5301812454631367e-1 -6.5737363964632056e-1];
t3 = [-6.0451734755080713e-2;
      -3.9533167111966377e-1;
       2.2979640654841407e0];                 
C3 = [ 8.7290852997159800e2                   0   9.4445161471037636e2;
                        0    8.7290852997159800e2 5.6447334036925656e2;
                        0                     0                    1   ];
                    

video = VideoReader("CAM2-GOPR0289-13943.mp4");
disp("       Total length of video file in seconds: " + video.Duration)
disp("         Height of the video frame in pixels: " + video.Height)
disp("          Width of the video frame in pixels: " + video.Width)
disp("            Bits per pixel of the video data: " + video.BitsPerPixel)
disp(" Video format as it is represented in Matlab: " + video.VideoFormat)
disp("Frame rate of the video in frames per second: " + video.FrameRate)

numberOfFrames = floor(video.FrameRate * video.Duration);
runningAverageRGB = zeros(video.Height, video.Width, 3);
for i = 1 : numberOfFrames
    frame = double(read(video, i));
    runningAverageRGB = ((i-1) * runningAverageRGB + frame)/i;
end
runningAverageRGB = uint8(runningAverageRGB);
imwrite(runningAverageRGB, 'background.png');

frameNumber = 80;
frame = read(video, frameNumber);
ballFrameRGB = extractBall(frame, runningAverageRGB, 50);
imwrite(ballFrameRGB, 'frame_' + string(frameNumber) + '.png');

ballFrame = rgb2gray(ballFrameRGB);
validI = [];
validJ = [];
for i = 1 : video.Height
    for j = 1 : video.Width
        if (ballFrame(i,j) > 128)
            validI = [validI i];
            validJ = [validJ j];
        end
    end
end
averageI = round(mean(validI));
averageJ = round(mean(validJ));
kernelSize = 2;
ballFrame(averageI-kernelSize:averageI+kernelSize,...
          averageJ-kernelSize:averageJ+kernelSize)...
      = zeros(2*kernelSize+1, 2*kernelSize+1);
imshow(ballFrame);

function result = extractBall(frame, averageRGB, threshold)
    result = frame - averageRGB;
    indices = find(result < threshold);
    result(indices) = 0;
end