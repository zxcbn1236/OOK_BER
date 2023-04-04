%%20210704
%%20220301：修订
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
%%
tic
clear
%%
%-----------------------------接收数据加载---------------------------------
local='.\';
% seq=csvread([local 'AWG_250bit_PAM4_.csv'],2,3);
% seq=csvread([local 'OSC_3p+zernike_5m_200khz_20us.csv'],2,3);%行列00起始点

seq=readmatrix('F:\张家豪\信号处理\3.20\3_30.csv');%行列00起始点

Array=seq(:,1);
% Tinterval=mean(diff(seq(:,1)));
Tinterval=5*10^(-11);%示波器采样时间500pts

Length=length(Array);
%%
%--------------------------------信号源设置参数(手动)----------------------------
%fs=1000000000; %设置的采样率
%point=1; %一个波特的点数

%fre=fs/point/1e6;%发射速率MBps：设置的采样率/一个波特的点数
fre=30;%发射速率MBps %设置的采样率/一个波特的点数

totalpoint=10000;%发射信号总点数
%baud_per_pattern=totalpoint/point;% 每个重复的波形pattern里面有多少个波特符号： 10k/20
baud_per_pattern=10000;% %10k/20

Fsend=fre*1e6;
order=1;%PAM 调制阶数
Ttotal=Tinterval*Length;
Npat=Fsend*Ttotal/baud_per_pattern;%number of pattern
sample_per_baud_temp=Length/(baud_per_pattern*Npat);%每个波特内的采样点数
sample_per_baud = round(sample_per_baud_temp);

Nseg=10000;%每段波特数
Array_data=seq(:,1);
for i = 1:length(Array_data)/round(sample_per_baud)/Nseg %分段数
    Array_passage(:,i) = Array_data(sample_per_baud*Nseg*(i-1)+1:sample_per_baud*Nseg*i);    
end

    %----------------------------------信号采样处理----------------------------
    %等间隔采样，然后硬判决，根据判决结果分组计算方差，以判决线
    %1\二分法将轨道分组，并算出硬判决界限；2、等间隔采样，然后使用之前的硬判决门限将轨道分组,同样是二分法，计算方差，方差之和最小的就是最佳采样点。
    %函数1，输入波形和轨道数，二分法求出各级判决门限；
    %函数2，输入取样之后的波形和各级判决门限，按条件，依次求轨道及方差；求出方差均值

    %----------根据采样后各级门限两旁的方差，寻找最佳采样点（最大方差）--------
for q = 1:length(Array)/round(sample_per_baud)/Nseg%分段数
    Array1 = Array_passage(:,q);
    threshold= Detection(Array1,order);%返回2^n-1个门限值
    %寻找方差最大的一组作为最佳采样
    for i=1:floor(sample_per_baud)
%         a=Array(round([i:floor(sample_per_baud):end]));
        a=Array1(([i:floor(sample_per_baud):end]));
        variance(i)=variance_calcualtion(a,threshold);
    end
    ind=find(variance==max(variance));
    %按最佳采样点采样
%     Bstream=Array(round([ind:sample_per_baud:end]));
    Bstream=Array1(ind:round(sample_per_baud):end);%按最佳采样点采样
    if ind>sample_per_baud
        Bstream=[Array1(1); Bstream];
        disp('sample again')
    end
    Bstream = Baud2bit(Bstream,order,threshold);
    %----------------比特同步，自相关求峰值------------------------------------
    %%
    source_signal = load('F:\张家豪\信号源\ook源\ook_TX_Signal_003.txt');
    T_sample=round(length(source_signal)/baud_per_pattern);
    Bstream_source=source_signal(1:T_sample:end);
    threshold_source = Detection(Bstream_source,order);
    Bstream_source = Baud2bit(Bstream_source,order,threshold_source);
%     Bstream_source=repmat(Bstream_source,floor(Npat),1);
    %维度矫正
%     Bstream=Bstream(1:length(Bstream_source));

        for shift=1:length(Bstream_source)
            Bstream_temp= circshift(Bstream,shift-1);
            R = corrcoef(Bstream_source,Bstream_temp);
            R_result(shift) = R(1,2);
        end
    Shift = find(R_result == max(max(R_result)));
    Bstream_shift= circshift(Bstream,Shift-1);
    diff = xor(Bstream_source,Bstream_shift);
    diff = diff*1;
    sum_q(:,q) = sum(diff);
    %---------------------截尾，转成bit求比特误码率----------------------------
%     Bstream_shift=Bstream_shift(1:baud_per_pattern*(Npat-1));
%     Bit_stream_shift=Baud2bit(Bstream_shift,order,threshold);
%     Bstream_source=Bstream_source(1:baud_per_pattern*(Npat-1));
%     Threshold_source= Detection(Bstream_source,order);%返回2^n-1个门限值
%     Bit_stream_source=Baud2bit(Bstream_source,order,Threshold_source);
% 
%     BER=sum(xor(Bit_stream_source,Bit_stream_shift))/length(Bit_stream_source)
end
BER = sum(sum_q)/Npat/10000
