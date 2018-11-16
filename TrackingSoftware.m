videoNames = ["CAM1-GOPR0333-21157.mp4","CAM2-GOPR0288-21180.mp4","CAM3-GOPR0342-21108.mp4";
                "CAM1-GOPR0333-25390.mp4","CAM2-GOPR0288-25413.mp4","CAM3-GOPR0342-25341.mp4";
                "CAM1-GOPR0333-28114.mp4","CAM2-GOPR0288-28137.mp4","CAM3-GOPR0342-28065.mp4";
                "CAM1-GOPR0333-31464.mp4","CAM2-GOPR0288-31487.mp4","CAM3-GOPR0342-31415.mp4";
                "CAM1-GOPR0333-34217.mp4","CAM2-GOPR0288-34240.mp4","CAM3-GOPR0342-34168.mp4";
                "CAM1-GOPR0334-6600.mp4","CAM2-GOPR0289-6563.mp4","CAM3-GOPR0343-6479.mp4";
                "CAM1-GOPR0334-14238.mp4","CAM2-GOPR0289-14201.mp4","CAM3-GOPR0343-14117.mp4";
                "CAM1-GOPR0334-16875.mp4","CAM2-GOPR0289-16838.mp4","CAM3-GOPR0343-16754.mp4";
                "CAM1-GOPR0334-26813.mp4","CAM2-GOPR0289-26776.mp4","CAM3-GOPR0343-26692.mp4";
                "CAM1-GOPR0334-36441.mp4","CAM2-GOPR0289-36404.mp4","CAM3-GOPR0343-36320.mp4"];

camBallStartPt = [560 315;
                  590 305;
                  1340 275];

for v = 1 : 1%size(videoNames,1)
    for c = 1 : 1%size(videoNames,2)
        filename = extractBefore(videoNames(v,c), ".mp4");
        disp("Processing " + filename)
        video = VideoReader("Videos/" + filename + ".mp4");
        disp("       Total length of video file in seconds: " + video.Duration)
        disp("         Height of the video frame in pixels: " + video.Height)
        disp("          Width of the video frame in pixels: " + video.Width)
        disp("            Bits per pixel of the video data: " + video.BitsPerPixel)
        disp(" Video format as it is represented in Matlab: " + video.VideoFormat)
        disp("Frame rate of the video in frames per second: " + video.FrameRate)

        % Obtain static background
        numberOfFrames = floor(video.FrameRate * video.Duration);
        runningAverageRGB = zeros(video.Height, video.Width, 3);
        for i = 1 : numberOfFrames
            frame = double(read(video, i));
            runningAverageRGB = ((i-1) * runningAverageRGB + frame)/i;
        end
        runningAverageRGB = uint8(runningAverageRGB);

        currentBallPos = camBallStartPt(c,:);
        offset = 20;
        
        % Ball image tracking
        ballFrameXY = zeros(numberOfFrames, 3) - 1;
        for frameNumber = 1 : numberOfFrames
            frame = read(video, frameNumber);
            
            frameRegion = frame(currentBallPos(1)-offset:currentBallPos(1)+offset,...
                                currentBallPos(2)-offset:currentBallPos(2)+offset,:);
            backgroundRGBRegion = runningAverageRGB(currentBallPos(1)-offset:currentBallPos(1)+offset,...
                                                    currentBallPos(2)-offset:currentBallPos(2)+offset,:);
            % ballFrameRGB = extractBall(frameRegion, backgroundRGBRegion, 50);
            ballFrameRGB = extractBall(frame, runningAverageRGB, 50);
            ballFrame = rgb2gray(ballFrameRGB);
            validI = [];
            validJ = [];
            %for i = 1 : 2 * offset + 1 %video.Height
            %    for j = 1 : 2 * offset + 1 %video.Width
            for i = 1 : video.Height
                for j = 1 : video.Width
                    if (ballFrame(i,j) > 128)
                        validI = [validI i];
                        validJ = [validJ j];
                    end
                end
            end

            if (length(validI) == 0)
                ballFrameXY(frameNumber,:) = [frameNumber -1 -1];
                continue;
            end
            %averageV = round(mean(validI)) - 1 - offset/2;
            %averageU = round(mean(validJ)) - 1 - offset/2;
            averageV = round(mean(validI));
            averageU = round(mean(validJ));
            currentBallPos = [averageV averageU];
            
            %[rectifiedU, rectifiedV] = getRectifiedUV(averageU, averageV, c);
            %kernelSize = 2;
            %ballFrame(averageI-kernelSize:averageI+kernelSize,...
            %          averageJ-kernelSize:averageJ+kernelSize)...
            %      = zeros(2*kernelSize+1, 2*kernelSize+1) + 255;
            %imshow(ballFrame);
            ballFrameXY(frameNumber,:) = [frameNumber averageU averageV]; %rectifiedU rectifiedV];
        end

        csvwrite('Annotation2d/' + string(v) + '/' + filename + '_2d.csv', ballFrameXY);
    end
end


function result = extractBall(frame, averageRGB, threshold)
    result = frame - averageRGB;
    indices = find(result < threshold);
    result(indices) = 0;
end
