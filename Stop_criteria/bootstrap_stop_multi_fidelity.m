function obj=bootstrap_stop_multi_fidelity(search_x,kriging_model_lfdel_lf,kriging_model_discrepancy,CI_factor)

% S is the sample set generated by MCS
% Kriging_model is the surrogate model generated by the last generation

% 
[search_y,mse]=estimated_value(search_x,kriging_model_lfdel_lf,kriging_model_discrepancy);
search_mse=sqrt(max(0,mse));
S_predict_safe=search_x(find(sum([search_y>=0  search_y-1.96*search_mse<0],2)==2),:);
S_predict_fail=search_x(find(sum([search_y<0  search_y+1.96*search_mse>0],2)==2),:);

%% analysis of the samples in the safe domian
[Safe_y,S_mse]=estimated_value(S_predict_safe,kriging_model_lfdel_lf,kriging_model_discrepancy);
Safe_mse=sqrt(max(0,S_mse));
% calculate the probability of failure
X_temp=-abs(Safe_y./Safe_mse);
p_fail=Gaussian_CDF(X_temp);
% P_fail=normcdf(0,Safe_y,Safe_mse);
mu_fail=size(S_predict_safe,1)*mean(p_fail);
if size(X_temp,1)>1
% estimate the bootstrapt confidence interval 
boot_sample = bootstrp(1000,@mean,p_fail);
boot_sample=sort(boot_sample,1);
k1=1000*CI_factor/2;
k2=1000*(1-CI_factor/2);
% k1=1000*0.025;
%  k2=1000*0.975;
 S_con_interval=[size(S_predict_safe,1)*boot_sample(k1,:),size(S_predict_safe,1)*boot_sample(k2,:)];
CI_safe_max=max(S_con_interval);
else 
    CI_safe_max=mu_fail;
end
%% analysis of the samples in the Failure domian
[Fail_y,F_mse]=estimated_value(S_predict_fail,kriging_model_lfdel_lf,kriging_model_discrepancy);
Fail_mse=sqrt(max(0,F_mse));
% calculate the probability of failure
X_temp=-abs(Fail_y./Fail_mse);
p_safe=Gaussian_CDF(X_temp);
% P_fail=normcdf(0,Safe_y,Safe_mse);
mu_safe=size(S_predict_fail,1)*mean(p_safe);
% estimate the bootstrapt confidence interval 
if size(X_temp,1)>1
boot_fail = bootstrp(1000,@mean,p_safe);
boot_fail=sort(boot_fail,1);
k1=1000*CI_factor/2;
k2=1000*(1-CI_factor/2);
% k1=1000*0.025;
%  k2=1000*0.975;
F_con_interval=[size(S_predict_fail,1)*boot_fail(k1,:),size(S_predict_safe,1)*boot_fail(k2,:)];
CI_fail_max=max(F_con_interval);
else 
    CI_fail_max=mu_safe;
end
%% final decision
Predict_fail=search_x(find(search_y<0),:);
N_f=size(Predict_fail,1);

error_1=abs((N_f/(N_f-CI_safe_max))-1);
error_2=abs((N_f/(N_f+CI_fail_max))-1);

obj=max(error_1,error_2);



end