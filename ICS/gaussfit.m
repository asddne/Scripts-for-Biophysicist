function [a] = gaussfit(corr,type,pixelsize,whitenoise);

% Usage: a = gaussfit(corr,type,pixelsize,whitenoise);
%set(gcbf,'pointer','watch');

[X,Y] = meshgrid(-((size(corr,2)-1)/2)*pixelsize:pixelsize:((size(corr,2)-1)/2)*pixelsize,-((size(corr,1)-1)/2)*pixelsize:pixelsize:(size(corr,1)-1)/2*pixelsize);
grid = [X Y];
   
[Y0, X0] = find(ismember(corr,max(max(corr))),size(corr,3));
X0 = mod(X0,size(corr,2));

%EvilX0 and Y0 are where remainder from mod was zero -- these are set to
%the "max" (ie size) of the corr
EvilX0 = find(ismember(X0,0));
X0(EvilX0) = size(corr,2);

    % Sets curve fit options, and sets lower bounds for amplitude and beam
    % radius to zero
    lb = [0 0 0 min(min(grid)) min(min(grid))];
    ub = [];
    
    weights = ones(size(corr));
    
    % If there's whitenoise, 2 highest values (NB this might be more than
    % two points!) in corr func are set to zero, and given no weight in the fit
    
if strcmp(whitenoise,'y')
    if strcmp('2d',type)
       for j=1:1
       i = find(ismember(corr(:,:,:),max(max(corr(:,:,:)))));
       ZerChan = i;
       corr(i) = [0];
       weights(i) = 0;
       end
    end
    if strcmp(type,'time')
       for j=1:1
       i = find(ismember(corr(:,:,1),max(max(corr(:,:,1)))));
       %corr(i) = [0];
       weights(i) = 0;
       end
    end    
end

%y0 = zeros(size(corr,3),1);
y0 = min(min(corr));
y0 = squeeze(y0);
g0 = max(max(corr));
g0 = squeeze(g0);

% wguess = zeros(size(corr,3),1);
% for i=1:size(corr,3)
% [Wy, Wx] = find(ismember(abs((corr(:,:,i)/g0(i) - exp(-1))),min(min(abs(corr(:,:,i)/g0(i) - exp(-1))))));
% Wx = mod(Wx,size(corr,2));
% wguess(i) = mean(( (Wx - X0(i)).^2  + (Wy - Y0(i)).^2   ).^(1/2))*pixelsize;
% end

wguess = 4*pixelsize*ones(size(g0));

% Converts from matrix index to LOCATION in pixelsize units
for i=1:size(corr,3)
  X0(i) = X(1,X0(i)); 
end
for i=1:size(corr,3)
  Y0(i) = Y(Y0(i),1);  
end

initguess = [g0 wguess y0 X0 Y0];
% plotgaussfit(a, corr, pixelsize, whitenoise);

    %curvefitoptions = optimset('Display','off');
    curvefitoptions = optimset('display','off','MaxFunEvals',10000,'MaxIter',5000,'TolFun',1e-8);

    %h = waitbar(0,'Fitting correlation functions...');
    
    % Fits each corr func separately
    if strcmp('2d',type)
    for i=1:size(corr,3)
        a0 = initguess(i,:);
%        a0xy(1:2) = initguess(i,1:2);
%         a0xy(3) = a0xy(2);
%         a0xy(4:6) = initguess(i,3:5);
        % Fits separate x and y radii
       %[a(i,:),res(i),RESIDUAL,EXITFLAG,OUTPUT,LAMBDA] = lsqcurvefit(@gauss2dwxy,a0xy,grid,corr(:,:,i).*weights(:,:,i),lb,ub,curvefitoptions,weights(:,:,i));
       
       [a(i,:),res(i),RESIDUAL,EXITFLAG,OUTPUT,LAMBDA] = lsqcurvefit(@gauss2d,a0,grid,corr(:,:,i).*weights(:,:,i),lb,ub,curvefitoptions,weights(:,:,i));

    end
    end
    
     if strcmp('2dimmobile',type)
    for i=1:size(corr,3)
        a0 = initguess(i,1:3);
        lb2=lb(1:3);
%        a0xy(1:2) = initguess(i,1:2);
%         a0xy(3) = a0xy(2);
%         a0xy(4:6) = initguess(i,3:5);
        % Fits separate x and y radii
       %[a(i,:),res(i),RESIDUAL,EXITFLAG,OUTPUT,LAMBDA] = lsqcurvefit(@gauss2dwxy,a0xy,grid,corr(:,:,i).*weights(:,:,i),lb,ub,curvefitoptions,weights(:,:,i));
       
       [a(i,:),res(i),RESIDUAL,EXITFLAG,OUTPUT,LAMBDA] = lsqcurvefit(@gauss2dimmobile,a0,grid,corr(:,:,i).*weights(:,:,i),lb2,ub,curvefitoptions,weights(:,:,i));

    end
    end

    if strcmp('time',type)
    for i=1:size(corr,3)
        if i==1
            a0 = initguess(i,:);
        else
            a0 = a(i-1,:);
        end
        funlist = {1, @(a,grid) exp(-((grid(:,1:size(grid,2)/2)-a(2)).^2+(grid(:,size(grid,2)/2+1:end)-a(3)).^2)/(a(1)^2))  }; 
        NLPstart = [a0(2) a0(4) a0(5)];
        options = optimset('disp','off');
        warning('off','MATLAB:rankDeficientMatrix');
        [INLP,ILP] = pleas(funlist,NLPstart,grid,corr(:,:,i),options);
        warning('on','MATLAB:rankDeficientMatrix');
        a(i,1) = ILP(2);
        a(i,2) = INLP(1);
        a(i,3) = ILP(1);
        a(i,4) = INLP(2);
        a(i,5) = INLP(3);
        a(i,6) = mean(mean((corr(:,:,i)-(a(1)*exp(-((grid(:,1:size(grid,2)/2)-a(4)).^2+(grid(:,size(grid,2)/2+1:end)-a(5)).^2)/(a(2)^2)) +a(3))).^2));
        %[a(i,:),res(i),RESIDUAL,EXITFLAG,OUTPUT,LAMBDA] = lsqcurvefit(@gauss2d,a0,grid,corr(:,:,i).*weights(:,:,i),lb,ub,curvefitoptions,weights(:,:,i));
    end
    end

%set(gcbf,'pointer','arrow');