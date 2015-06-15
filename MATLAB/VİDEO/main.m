clear all;
close all;
clc;

ite = 10;  %iterasyon sayisi
alpha = 50; %yumu�aklik katsayisi
arkaplan = 0;   %arkaplan ayr��t�rma yapmak i�in de�eri 1 girebilirsiniz(optik ak�� i�in 0)
arkaplan_sinir = 0.05;  %arkaplan ayr��t�rmada kullan�lacak e�ik de�eri
gauss_size = 5; %gauss filtremizin kernel boyutu l�tfen tek say� giriniz


Object=VideoReader('viptraffic.avi');  %i�lem yapaca��m�z video nun okunmas�

%videonun �zelliklerinin al�nmas�
oldvidHeight=Object.Height;
oldvidWidth=Object.Width;
framerate=Object.FrameRate;
NumFrames = Object.NumberOfFrames;

%��z�n�rl�k d��t�kten sonraki boyutlar
vidHeight=ceil(oldvidHeight*360/oldvidWidth);
vidWidth=ceil(oldvidWidth*360/oldvidWidth);

kernel_1=[1/12 1/6 1/12;1/6 0 1/6;1/12 1/6 1/12];
vid=zeros(vidHeight,vidWidth,NumFrames);
uvid=zeros(vidHeight,vidWidth,NumFrames-1);
vvid=zeros(vidHeight,vidWidth,NumFrames-1);

%gauss filtremizin olu�turulmas�
H = fspecial('gaussian',gauss_size);

%arkaplan ayr��t�rma i�lemi
if arkaplan==1
vidrgb=zeros(vidHeight,vidWidth,3,NumFrames);
opvid=zeros(vidHeight,vidWidth,NumFrames-1);

%gri d�zey gauss filtrelenmi� d���k ��z�n�rl�kl� videonun elde edili�i
for k=1:NumFrames
    resized=imresize(rgb2gray(read(Object,k)),360/oldvidWidth);
    vid(:,:,k)=imfilter(im2double(resized),H,'replicate');
end
%rgb gauss filtrelenmi� d���k ��z�n�rl�kl� videonun elde edili�i
for k=1:NumFrames
    resized=imresize(read(Object,k),360/oldvidWidth);
    vidrgb(:,:,:,k)=imfilter(im2double(resized),H,'replicate');
end
clear Object;clear resized;

%bu k�s�m raporda anlat�lm��t�
for k=2:NumFrames
    [Dx,Dy,Dt] = turev(vid(:,:,k-1),vid(:,:,k));
    for i=1:ite
      uAvg=conv2(uvid(:,:,k-1),kernel_1,'same');
      vAvg=conv2(vvid(:,:,k-1),kernel_1,'same');
      uvid(:,:,k-1)= uAvg - ( Dx.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
      vvid(:,:,k-1)= vAvg - ( Dy.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
    end
    %optik ak���n �iddetini bulal�m
    opvid(:,:,k-1)=sqrt(uvid(:,:,k-1).^2+vvid(:,:,k-1).^2);
end
clear vid;clear uvid;clear vvid;

%videonun renklere ayr��t�r�lmas�
vidr=vidrgb(:,:,1,:);
vidg=vidrgb(:,:,2,:);
vidb=vidrgb(:,:,3,:);

%e�ik de�erin alt�nda kalan hareketlerin s�f�rlanmaso
vidr(opvid*255*255<arkaplan_sinir)=0;
vidg(opvid*255*255<arkaplan_sinir)=0;
vidb(opvid*255*255<arkaplan_sinir)=0;

%arkaplandan ayr��t�r�lm�� g�r�nt�n�n birle�imi
vidrgb(:,:,1,:)=vidr;
vidrgb(:,:,2,:)=vidg;
vidrgb(:,:,3,:)=vidb;
clear vidr;clear vidg;clear vidb;

%dosyaya yazmak
writerObj = VideoWriter('ARKAPLANCIKARMA.avi');
writerObj.FrameRate = framerate;
open(writerObj);
writeVideo(writerObj,vidrgb*0.99);
close(writerObj);
end

%hsv renk �emberiyle optik ak���n g�sterimi
if arkaplan==0
    
    %gri d�zey gauss filtrelenmi� d���k ��z�n�rl�kl� videonun elde edili�i
for k=1:NumFrames
    resized=imresize(rgb2gray(read(Object,k)),360/oldvidWidth);
    vid(:,:,k)=imfilter(im2double(resized),H,'replicate');
end

clear Object;clear resized;
op3vid=zeros(vidHeight,vidWidth,3,NumFrames-1);

for k=2:NumFrames
    [Dx,Dy,Dt] = turev(vid(:,:,k-1),vid(:,:,k));
    for i=1:ite
      uAvg=conv2(uvid(:,:,k-1),kernel_1,'same');
      vAvg=conv2(vvid(:,:,k-1),kernel_1,'same');
      uvid(:,:,k-1)= uAvg - ( Dx.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
      vvid(:,:,k-1)= vAvg - ( Dy.*(( Dx.*uAvg ) + ( Dy.*vAvg ) + Dt ) )./( alpha^2 + Dx.*Dx + Dy.*Dy);
    end
    %optik ak���n renk ile kodlanmas�
    op3vid(:,:,:,k-1)=computeColor(uvid(:,:,k-1)*255*255,vvid(:,:,k-1)*255*255);
end
clear vid;clear uvid; clear vvid;
writerObj2 = VideoWriter('OPT�KAK�S.avi');
writerObj2.FrameRate = framerate;
open(writerObj2);
writeVideo(writerObj2,op3vid/255);
close(writerObj2);
end

clear all;

