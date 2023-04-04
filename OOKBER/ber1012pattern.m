%%20210704
%%
tic
clear
%% -----------------------------接收数据加载---------------------------------------------------------------
local='D:\OFC2022\OSC\OSCdata\10m\';
fre=50;%波特率单位MBps
seq=csvread([local 'zernike_100M_1ms_1.csv'],2,3);

Array=seq(:,2);
Tinterval=mean(diff(seq(:,1)));
Length=length(Array);
%% --------------------------------信号源设置参数(手动)-----------------------------------------------------
baud_per_pattern=250;%每个重复的波形pattern里面有多少个波特符号

Fsend=fre/250*1e6;%frequency send :200k（单位：pattern per second，pico的发送速度）
order=2;%PAM 幅度级=2^调制阶数，2，4，8，16
Ttotal=Tinterval*Length;%总的采样时间
Npat=Fsend*Ttotal;%number of pattern，采样到的波形pattern数,应该是整数
sample_per_baud=Length/(baud_per_pattern*Npat);%每个波特的采样点数
%% 分组，用于分段同步，避免时间漂移误差累积
%后期将原始序列分组操作，
%分组同步，避免积累时钟误差
num_pattern = 50;%每个分组帧含有的波形pattern的数目
for i = 1:round(Npat)/num_pattern  %分组数
    Array_passage(:,i) = Array(sample_per_baud*250*num_pattern*(i-1)+1:sample_per_baud*250*num_pattern*i);    
end

%% ----------------------------------信号采样处理----------------------------------------------------------
%等间隔采样，然后硬判决，根据判决结果分组计算方差，以判决线
%1\二分法将轨道分组，并算出硬判决界限；2、等间隔采样，然后使用之前的硬判决门限将轨道分组,同样是二分法，计算方差，方差之和最小的就是最佳采样点。
%函数1，输入波形和轨道数，二分法求出各级判决门限；
%函数2，输入取样之后的波形和各级判决门限，按条件，依次求轨道及方差；求出方差均值
%% ----------根据采样后各级门限两旁的方差，寻找最佳采样点（最大方差）--------------------------------
for q = 1:round(Npat)/num_pattern %分组数
    Array1 = Array_passage(:,q);%分组处理
    threshold= Detection(Array1,order);%返回2^n-1个门限值
    for i=1:floor(sample_per_baud) %遍历起始点
%         a=Array(round([i:floor(sample_per_baud):end]));
        a=Array1(i:floor(sample_per_baud):end); %按周期取出每个波特的判决点
        variance(i)=variance_calcualtion(a,threshold); %求方差，找出方差最大的一组，就是最佳判决采样点序列
    end
    ind=find(variance==max(variance));
%     Bstream=Array(round([ind:sample_per_baud:end]));%按最佳采样点采样
    Bstream=Array1(ind:floor(sample_per_baud):end);%按最佳采样点采样
    
    if ind>sample_per_baud
        Bstream=[Array1(1); Bstream];
        disp('sample again')
    end
%% ----------------比特同步，自相关求峰值-------------------------------------------------------------    
    source_signal = load('D:\OFC2022\AWG_250bit_PAM4_.csv');
    T_sample=round(length(source_signal)/baud_per_pattern); %发射，每个波特的采样点数
    Bstream_source=source_signal(1:T_sample:end); %判决序列，每个波特，一个点
    Bstream_source=repmat(Bstream_source,num_pattern,1);%重复和分组长度一致，直接比较

    for shift=1:baud_per_pattern  %按符号移位，找到同步符号位
        Bstream_temp= circshift(Bstream,shift-1);
        R = corrcoef(Bstream_source,Bstream_temp);
        R_result(shift) = R(1,2);
    end
    
    Shift = find(R_result == max(max(R_result)));%自相关峰对应得同步符号位
    Bstream_shift= circshift(Bstream,Shift-1); %循环移位实现同步
    Bit_stream_shift=Baud2bit(Bstream_shift,order,threshold); %幅度调制，波特2比特，求比特误码率
    %原信号，参考信号
    Threshold_source= Detection(Bstream_source,order);%返回2^n-1个门限值
    Bit_stream_source = Baud2bit(Bstream_source,order,Threshold_source);
    %将源信号和移位之后的实测信号，做异或，求误码率
    diff = xor(Bit_stream_source,Bit_stream_shift);    
    diff = diff*1;
    sum_q(:,q) = sum(diff);
%% ---------------------截尾，转成bit求比特误码率----------------------------------------------------------
%     Bstream_shift=Bstream_shift(1:baud_per_pattern*(Npat-1));
%     Bit_stream_shift=Baud2bit(Bstream_shift,order,threshold);
%     Bstream_source=Bstream_source(1:baud_per_pattern*(Npat-1));
%     Threshold_source= Detection(Bstream_source,order);%返回2^n-1个门限值
%     Bit_stream_source=Baud2bit(Bstream_source,order,Threshold_source);
% 
%     BER=sum(xor(Bit_stream_source,Bit_stream_shift))/length(Bit_stream_source)
end
% BER = sum(sum_q)/Npat/500;
BER = sum(sum_q)/length(Bit_stream_source)/(Npat/num_pattern)