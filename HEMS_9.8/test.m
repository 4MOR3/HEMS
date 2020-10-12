% ����yamlip���TSP����
clear;clc;close all;
d = load('E:\\tsp_dist_matrix.txt')';
n = size(d,1);
% ���߱���
x = binvar(n,n,'full');
u = sdpvar(1,n);
% Ŀ��
z = sum(sum(d.*x));
% Լ�����
C = [];
for j = 1:n
    s = sum(x(:,j))-x(j,j);
    C = [C,   s  == 1];
end
for i = 1:n
    s = sum(x(i,:)) - x(i,i);
    C = [C, s  == 1];
end
for i = 2:n
    for j = 2:n
        if i~=j
            C = [C,u(i)-u(j) + n*x(i,j)<=n-1];
        end
    end
end
% ��������
ops = sdpsettings('verbose',0,'solver','cplex');
% ���
result  = optimize(C,z);
if result.problem== 0
    value(x)
    value(z)
else
    disp('�������г���');
end