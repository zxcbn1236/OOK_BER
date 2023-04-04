function  variance=variance_calcualtion(Array,threshold)
if length(threshold)==1
    err=Array-threshold;
    mse=mean(err.^2);
else
    for i = 1:length(threshold)
        if i == length(threshold)
            subA = Array(Array<threshold(i-1));      
            error = subA - threshold(i);
            mse(i) =  mean(error.^2);
        else if i == 1
            subA = Array(Array>threshold(i+1));      
            error = subA - threshold(i);
            mse(i) =  mean(error.^2);
            else
                subA = Array((Array<threshold(i-1))&(Array>threshold(i+1)));
                error = subA - threshold(i);
                mse(i) = mean(error.^2);
            end
        end
    end
end
variance = mean(mse);









