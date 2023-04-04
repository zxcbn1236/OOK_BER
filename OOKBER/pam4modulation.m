clear all;
clc;
%PPM调制

%参数设置

N = 160;%码元个数
Fs= 100;%采样速率
Ts=1/Fs;%采样间隔
Rs = 1;%码元速率
Upsamplerate=Fs/Rs;
RollOff=0.25;
Span=6;
Sps=Upsamplerate;



sys=randi([1,2 ],1,N);%生成符号序列
sys_4pam=sys*2-3;%4-pam调制
%figure(1);
%subplot(2,1,1);
%stem(sys);
%subplot(2,1,2);
%stem(sys_4pam);

%升采样
sys_4pam_upsmp=zeros(1,N*Upsamplerate);
sys_4pam_upsmp(1:Upsamplerate:end)=sys_4pam;

%脉冲成形（rcosdesign）
h=rcosdesign(RollOff,Span,Sps,'sqrt');
rcos_sys_4pam=conv(h,sys_4pam_upsmp);
sendSig=rcos_sys_4pam;

%脉冲成形
rectangle_h=ones(1,Upsamplerate);
rectangel_sys_4pam=conv(rectangle_h,sys_4pam_upsmp);


figure(2);
%subplot(2,1,1);
%plot(rcos_sys_4pam);
%subplot(2,1,1);

plot(rectangel_sys_4pam);

disp(rectangel_sys_4pam);
xlswrite('ook.xlsx',rectangel_sys_4pam');

%save pam4.txt -ascii rectangel_sys_4pam;


