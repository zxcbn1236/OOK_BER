%���벨�κͽ���������2^n-1������ֵ����ֵ��ֻ������������У����ԸĽ������Զ��������⣩���ݹ�����
function threshold=Detection(Array,order)
    thres=mean(Array);
    if order==1
        threshold=thres;
        return  
    end
    
    AA=Array(Array>=thres);
    AB=Array(Array<=thres);
    
    %�ݹ���ַ�������,���룬�����У����������������ֵ
    thresA=Detection(AA,order-1);
    thresB=Detection(AB,order-1);
    threshold=[thresA,thres,thresB];




