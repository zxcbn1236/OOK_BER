%�ɲ��������ɱ���������
%���벨��������������ֵ���������������
%
function Bit_stream=Baud2bit(Array,order,threshold)
    Array_temp=Array;
    if 2^order-1~=length(threshold)
        disp('wrong!Baud2bit');
        return
    end
    
    if length(threshold)==1        
        Array_temp(Array>=threshold)=1;
        Array_temp(Array<threshold)=0;
        Bit_stream=Array_temp;
        return
    else    
        for i =1:length(threshold)
            if i==1
                Array_temp(Array>threshold(i+1))=2^order-1;
            else
                if i==length(threshold)
                    Array_temp(Array<threshold(i-1))=0;
                else
                    Array_temp((Array<threshold(i-1))&(Array>threshold(i)))=2^order-i;
                end
            end
        end
    end
    temp=dec2bin(Array_temp)';
    Bit_stream=str2num(temp(:));